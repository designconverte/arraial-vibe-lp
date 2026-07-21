# Deploy — Staging e Produção

## Ambientes

| Ambiente | URL | Atualiza quando | Para quê |
|----------|-----|-----------------|----------|
| **Staging** | https://designconverte.github.io/arraial-vibe-lp/ | a cada `git push` (automático, ~1 min) | testar com segurança, mandar pro cliente aprovar |
| **Produção** | https://vibearraial.com.br | só via `bash deploy.sh` (manual) | o site oficial, que o público acessa |

O cliente/tráfego só vê **produção**. Nada chega lá sem passar por staging e por um comando explícito.

## Fluxo de trabalho

```
1. editar arquivos
2. git add -A && git commit -m "..." && git push     -> staging atualiza sozinho
3. testar em https://designconverte.github.io/arraial-vibe-lp/
4. aprovado?  ->  bash deploy.sh                     -> vai para produção
```

## Comandos

```bash
bash deploy.sh --status     # o que está no ar vs. o que está no git
bash deploy.sh --dry-run    # roda todas as verificações SEM publicar
bash deploy.sh              # publica em produção
bash deploy.sh --force      # pula as travas de git (usar só em emergência)
```

## Travas de segurança

O deploy **aborta** se qualquer uma falhar:

1. **Árvore de trabalho limpa** — nada pode estar sem commit, para que produção corresponda a um commit rastreável.
2. **Sincronizado com `origin/main`** — garante que *o que você testou no staging é exatamente o que vai pro ar*.
3. **Contagem mínima de arquivos** (local e após upload) — protege contra publicar um pacote incompleto.
4. **Publicação em duas etapas** — os arquivos sobem primeiro para uma área de preparo (`.deploy_staging`) e só substituem a produção **depois de validados**. Se o upload falhar no meio, produção fica intacta.

## Cuidados com o servidor

⚠️ **A conta Hostinger hospeda ~40 sites de clientes.** O script:

- opera **exclusivamente** em `~/domains/vibearraial.com.br/`;
- usa `rsync --delete` apenas de uma origem já validada e restrita a esse `public_html` (para remover arquivos antigos que saíram do projeto);
- **preserva** `.well-known/` (validação do SSL — apagar quebraria a renovação do certificado) e `.htaccess`.

## Rastreabilidade

Cada deploy grava o commit publicado em `~/domains/vibearraial.com.br/.deployed-commit` (fora do `public_html`, portanto não acessível pela web). É o que o `--status` lê para dizer o que está no ar.

## Rollback

```bash
git checkout <commit-anterior>
bash deploy.sh --force
git checkout main
```

## Conexão

Atalho SSH `vibearraial` em `~/.ssh/config` (host, porta 65002, usuário e chave `id_ed25519_vibearraial`). Autenticação por chave — nenhuma senha em script ou repositório.
