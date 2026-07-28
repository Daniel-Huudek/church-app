# Uploads AWS S3 — site institucional

Imagens do site (banner da série, foto da liderança, etc.) sobem para um bucket S3.

## Fluxo

1. No app: **Painel → Site → Enviar imagem (S3)**
2. API: `POST /website/uploads?kind=logo|leadership|series|news|streams|events|general` (multipart)
3. Objeto salvo em `website/{kind}/{uuid}.{ext}`
4. URL pública gravada no CMS (`PUT /website`)
5. Site consome a URL no `GET /website`

Slots cobertos: logo, banner da série, eventos, notícias, transmissões e liderança.

## Variáveis

```bash
AWS_REGION=us-east-1
AWS_ACCESS_KEY_ID=...
AWS_SECRET_ACCESS_KEY=...
AWS_S3_BUCKET=church-app-media
AWS_S3_PUBLIC_BASE_URL=https://church-app-media.s3.us-east-1.amazonaws.com
```

Use CloudFront em `AWS_S3_PUBLIC_BASE_URL` se preferir CDN.

### Bucket (mínimo)

- Bloquear acesso público “de conta” conforme sua política, **ou**
- Objetos públicos via bucket policy de leitura em `website/*`
- CORS permitindo `PUT`/`POST` não é necessário (upload é pela API)

Exemplo de policy de leitura pública só da pasta do site:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "PublicReadWebsiteMedia",
      "Effect": "Allow",
      "Principal": "*",
      "Action": ["s3:GetObject"],
      "Resource": ["arn:aws:s3:::church-app-media/website/*"]
    }
  ]
}
```

IAM do usuário da API precisa de `s3:PutObject` (e idealmente `s3:AbortMultipartUpload`) no bucket.
