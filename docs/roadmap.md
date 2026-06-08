# Roadmap VanGo

## Status atual: MVP concluído ✅
> Branch de testes: `hml` | Branch de produção: `main`

---

## Sprint 1 ✅ — Base do projeto
- Estrutura Clean Architecture (domain / data / presentation)
- Firebase Auth + Firestore conectados
- Login e cadastro
- Roteamento por papel (motorista / estudante)
- Fluxo de criar / entrar em sala

---

## Sprint 2 ✅ — Funcionalidades core
- Dashboard do motorista com streams em tempo real
- Gerenciamento de salas (criar, editar, excluir)
- Gerenciamento de faculdades via CEP (ViaCEP + Nominatim)
- Múltiplos endereços do aluno (estilo iFood)
- Chamada diária do aluno (vou e volto / só ida / só volta / não vou)
- Seleção de endereço de embarque e desembarque por dia
- Aluno entra/sai de sala por código de acesso
- Suporte a múltiplas salas (motorista e aluno)

---

## Sprint 3 ✅ — Rotas e navegação
- Montagem de rota de ida e volta pelo motorista
- Otimização de rota via OSRM (TSP — Traveling Salesman Problem)
- Rota ativa: GPS compartilhado em tempo real
- Geofence automático: modal abre ao chegar perto da parada
- Aluno marca "Estou liberado" para rota de volta
- Mapa da van em tempo real para o aluno
- Notificação de proximidade do motorista (< 300m)
- Listener de liberações com notificação in-app para motorista

---

## Sprint 4 ✅ — Polimento e MVP
- Rota sempre otimizada pela localização atual do motorista
- Rota de volta: filtra apenas alunos liberados + adiciona em tempo real
- Faculdade (volta): aguarda todos liberados antes de confirmar parada
- Mapa gira na direção do movimento (heading do GPS)
- Banner turn-by-turn com instrução de curva em português
- Google Maps com todas as paradas pendentes
- Waze na próxima parada
- Notificação sonora com TTS em pt-BR ("Maria liberada")
- Raio de geofence: 40m → 300m
- Validação de email e máscara de telefone no cadastro
- Endereço criado automaticamente na subcoleção `addresses/` no cadastro
- Nome do app corrigido para "VanGo"
- Guia completo de uso: `GUIA_VANGO.md`
- Bug fixes: ordem OSRM correta, notificação dedup por sessão, snackbar sem spam

---

## Distribuição atual

| Plataforma | Método | Link/Arquivo |
|---|---|---|
| Android | APK via Google Drive | `build/app/outputs/flutter-apk/app-release.apk` |
| iOS / Web | PWA via Firebase Hosting | https://app-de-van-5f05d.web.app |

---

## Pendências futuras (pós-MVP)

- [ ] Ícone personalizado do app (aguarda arte)
- [ ] Notificações push em background (requer Firebase Blaze — plano pago)
- [ ] Notificação diária agendada de chamada
- [ ] Múltiplos endereços com mapa interativo estilo iFood
- [ ] Histórico de rotas por dia
- [ ] Relatório de frequência por aluno

---

## Comandos para nova versão

```powershell
# Android
flutter build apk --release

# Web / iOS PWA
flutter build web --no-tree-shake-icons
firebase deploy --only hosting
```
