import { ApiProperty } from '@nestjs/swagger';
import { IsJWT } from 'class-validator';

export class EasysaleExchangeDto {
  @ApiProperty({
    description:
      'JWT HS256 emitido pelo EasyManager (manager/chat/sso-token.php)',
  })
  @IsJWT()
  token: string;
}
