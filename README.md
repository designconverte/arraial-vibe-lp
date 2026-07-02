# Arraial Vibe Turismo — Landing Page

Landing page de conversão (passeio de barco em Arraial do Cabo) focada em gerar conversas no WhatsApp.
Single-page autocontida: HTML + CSS + JS num único `index.html`, com fotos reais da embarcação em `assets/`.

## Como publicar

1. Suba a pasta `arraial-vibe-lp/` inteira para qualquer hospedagem estática (Hostgator, Vercel, Netlify, S3, etc.).
2. O arquivo de entrada é `index.html`. Mantenha a pasta `assets/` ao lado dele.
3. Rode localmente para testar: `npx serve` ou `python -m http.server` dentro da pasta e abra `http://localhost:8000`.

## Stack / features

- **Fonte:** Outfit (Google Fonts) — exigência do brief.
- **Design:** premium tropical acessível — azul-marinho oceânico + turquesa (acento) + dourado (destaque).
- **Scroll cinematográfico:** GSAP + ScrollTrigger + Lenis + SplitType (com `typeof` checks — o site funciona mesmo se algum CDN falhar). Efeitos pesados (parallax/pin) desativados no mobile.
- **Conversão:** CTA WhatsApp contextual por seção (mensagem pré-preenchida diferente em cada ponto), sticky bar no mobile, botão flutuante no desktop.
- **SEO:** title/meta/OG + JSON-LD (`TravelAgency/LocalBusiness` + `FAQPage`). Imagem hero com `preload`.
- **Acessibilidade:** HTML semântico, `alt` em todas as imagens, foco/hover, `prefers-reduced-motion`, safe-area no iPhone.
- **Galeria:** lightbox com navegação por teclado e setas.

## Eventos de analytics (GA4/GTM via dataLayer)

Já disparados por `window.dataLayer.push`: `click_whatsapp_{header|hero|menu|roteiro|experiencia|reservar|final|sticky|float|footer}`, `click_instagram`, `view_roteiro`, `view_galeria`, `view_faq`.
Para ativar, basta colar o snippet do GTM/GA4 no `<head>`.

## ⚠️ Antes de publicar — confirmar com o cliente (Regra "No Invention")

O conteúdo usa **apenas dados confirmados**. Onde havia dúvida, o texto orienta "confirme pelo WhatsApp".
Validar e ajustar no `index.html` quando o cliente confirmar:

- [ ] **Preço** R$ 79,99 (hoje exibido como "a partir de", sujeito à disponibilidade)
- [ ] **Duração** 4h (confirmar se não há versão de 5h)
- [ ] Razão social completa (rodapé / JSON-LD)
- [ ] Horários de saída e tolerância de chegada
- [ ] Formas de pagamento (Pix/cartão/dinheiro/parcelamento)
- [ ] Taxa de embarque e taxas extras
- [ ] Políticas de chuva, cancelamento e remarcação
- [ ] Wi-Fi, guia, fotógrafo, barzinho, cooler, bote de apoio, toboágua (hoje tratados como "confirmar pelo WhatsApp"; o toboágua aparece nas fotos reais, mas não como promessa em texto)
- [ ] Regra das cortesias (cortesia vs. open bar — hoje usamos "cortesia")
- [ ] Autorização de uso das fotos com passageiros identificáveis
- [ ] Domínio real (atualizar `canonical`/OG/JSON-LD, hoje com placeholder `arraialvibe.com.br`)
- [ ] Prova social real (Google/Instagram) — seção pode ser adicionada quando houver material

## Nomenclatura dos assets (origem)

Imagens copiadas de `../projeto/` e renomeadas semanticamente. Vídeo: `assets/video/arraial-vibe.mp4`.
Sugestão de performance futura: converter JPGs para WebP/AVIF e gerar variações mobile/desktop.
