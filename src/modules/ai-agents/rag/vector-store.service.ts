import { Injectable, Logger } from '@nestjs/common';
import { PrismaService } from '../../../database/prisma.service';
import type { SearchResult, SearchScope, VectorEntry } from './types';

/**
 * MySQL-backed store for RAG entries (tabela `ai_vector_entries`, modelada
 * no Prisma como `AiVectorEntry`).
 *
 * MySQL não tem equivalente ao pgvector, então:
 * - o embedding (1536 floats) é serializado como Float32Array em BLOB
 *   (~6 KB/linha vs ~19 KB do JSON text);
 * - a busca filtra candidatos pelo escopo via índices normais e calcula a
 *   similaridade de cosseno na aplicação.
 *
 * Trade-off dimensionado: com escopo (agent/contact/conversation) o conjunto
 * de candidatos é pequeno; sem escopo, o fetch é limitado aos
 * `CANDIDATE_LIMIT` mais recentes. Adequado até dezenas de milhares de
 * entradas por escopo — acima disso, migrar para MySQL 9 `VECTOR` ou um
 * serviço de busca vetorial dedicado.
 */
@Injectable()
export class VectorStoreService {
  private readonly logger = new Logger(VectorStoreService.name);

  /** Máximo de candidatos carregados do banco por busca. */
  private static readonly CANDIDATE_LIMIT = 2000;

  constructor(private readonly prisma: PrismaService) {}

  /**
   * Insere ou atualiza uma entrada. Re-indexar uma mensagem sobrescreve em
   * vez de duplicar (id é determinístico: `${ownerType}:${ownerId}`).
   */
  async upsert(entry: VectorEntry): Promise<void> {
    const embedding = this.encodeEmbedding(entry.embedding);
    const data = {
      ownerType: entry.ownerType,
      ownerId: entry.ownerId,
      conversationId: entry.conversationId ?? null,
      agentId: entry.agentId ?? null,
      contactId: entry.contactId ?? null,
      content: entry.content,
      embedding,
      metadata: entry.metadata ?? {},
    };

    await this.prisma.aiVectorEntry.upsert({
      where: { id: entry.id },
      create: { id: entry.id, ...data },
      update: {
        embedding,
        content: entry.content,
        metadata: entry.metadata ?? {},
      },
    });
  }

  /**
   * Bulk-upsert sequencial — o indexer já é concorrente no nível do job
   * BullMQ; se virar gargalo, trocar por `createMany` + update dos conflitos.
   */
  async upsertMany(entries: VectorEntry[]): Promise<void> {
    for (const entry of entries) {
      await this.upsert(entry);
    }
  }

  /**
   * Busca por similaridade de cosseno (0..1, maior = mais similar),
   * calculada na aplicação sobre os candidatos do escopo.
   */
  async search(
    queryVector: number[],
    scope: SearchScope,
    k = 5,
    minScore = 0.7,
  ): Promise<SearchResult[]> {
    const where: Record<string, unknown> = {};
    if (scope.agentId) where.agentId = scope.agentId;
    if (scope.contactId) where.contactId = scope.contactId;
    if (scope.conversationId) where.conversationId = scope.conversationId;
    if (scope.ownerType && scope.ownerType !== 'any') {
      where.ownerType = scope.ownerType;
    }

    const candidates = await this.prisma.aiVectorEntry.findMany({
      where,
      orderBy: { createdAt: 'desc' },
      take: VectorStoreService.CANDIDATE_LIMIT,
    });

    if (candidates.length === VectorStoreService.CANDIDATE_LIMIT) {
      this.logger.warn(
        `Vector search hit candidate cap (${VectorStoreService.CANDIDATE_LIMIT}) — ` +
          `scope ${JSON.stringify(scope)}; resultados antigos podem ficar de fora.`,
      );
    }

    const query = Float32Array.from(queryVector);
    const queryNorm = this.norm(query);

    return candidates
      .map((row) => {
        const vec = this.decodeEmbedding(row.embedding);
        return {
          entry: {
            id: row.id,
            ownerType: row.ownerType as VectorEntry['ownerType'],
            ownerId: row.ownerId,
            conversationId: row.conversationId ?? undefined,
            agentId: row.agentId ?? undefined,
            contactId: row.contactId ?? undefined,
            content: row.content,
            embedding: [], // search omite o vetor cru pra economizar banda
            metadata: (row.metadata as Record<string, any>) ?? {},
            createdAt: row.createdAt.toISOString(),
          },
          score: this.cosineSimilarity(query, queryNorm, vec),
        };
      })
      .filter((r) => r.score >= minScore)
      .sort((a, b) => b.score - a.score)
      .slice(0, k);
  }

  async delete(id: string): Promise<void> {
    await this.prisma.aiVectorEntry.deleteMany({ where: { id } });
  }

  /**
   * Remove toda entrada ligada a um owner. Útil quando um fact é deletado
   * upstream e o vector store precisa refletir isso.
   */
  async deleteByOwner(
    ownerType: VectorEntry['ownerType'],
    ownerId: string,
  ): Promise<void> {
    await this.prisma.aiVectorEntry.deleteMany({
      where: { ownerType, ownerId },
    });
  }

  // ─── Serialização & matemática ─────────────────────────────────────

  private encodeEmbedding(vector: number[]): Uint8Array<ArrayBuffer> {
    const floats = Float32Array.from(vector);
    return new Uint8Array(floats.buffer, 0, floats.byteLength);
  }

  private decodeEmbedding(blob: Uint8Array): Float32Array {
    // slice() garante um ArrayBuffer próprio e alinhado (byteOffset 0).
    const copy = blob.slice();
    return new Float32Array(
      copy.buffer,
      0,
      copy.byteLength / Float32Array.BYTES_PER_ELEMENT,
    );
  }

  private norm(v: Float32Array): number {
    let sum = 0;
    for (let i = 0; i < v.length; i++) sum += v[i] * v[i];
    return Math.sqrt(sum);
  }

  private cosineSimilarity(
    query: Float32Array,
    queryNorm: number,
    candidate: Float32Array,
  ): number {
    if (query.length !== candidate.length || queryNorm === 0) return 0;
    let dot = 0;
    let candSum = 0;
    for (let i = 0; i < query.length; i++) {
      dot += query[i] * candidate[i];
      candSum += candidate[i] * candidate[i];
    }
    const candNorm = Math.sqrt(candSum);
    if (candNorm === 0) return 0;
    return dot / (queryNorm * candNorm);
  }
}
