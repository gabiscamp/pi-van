# VanGo - Sprint 4: CRUD de Salas, Rotas Reais e Navegação Automática

Esta sprint completa as funcionalidades pedidas, refletindo o funcionamento
real de uma van universitária.

## 1. CRUD de Salas pelo Motorista
Tela `ManageSalasPage` (rota `/manage-salas`, acessível pelo Painel e pelo
Perfil do motorista):
- Criar, listar, editar e excluir salas.
- Visualizar os alunos vinculados a cada sala.
- Tornar uma sala ativa.
Ao excluir uma sala, os alunos são desvinculados automaticamente.

## 2 e 3. Lógica de Rotas (Ida / Volta) baseada na Chamada do Dia
`RouteBuilderService` (domínio puro) monta as paradas a partir dos votos do dia:

**Ida** — leva os alunos às faculdades:
1. Primeiro busca TODOS os alunos (paradas de embarque em casa).
2. Depois organiza as entregas nas faculdades.
3. Faculdade só aparece se houver aluno indo para ela.
4. Alunos da mesma faculdade são agrupados em UMA parada.

**Volta** — leva os alunos para casa:
1. Começa pelas faculdades (origem).
2. Depois os desembarques nas casas.
3. Só aparecem alunos que marcaram volta.
4. Só aparecem faculdades com alunos retornando.

Em ambos os casos: ausentes/pendentes não aparecem, faculdades sem alunos
não aparecem, endereços não usados não aparecem. Tudo é gerado dinamicamente
a partir da chamada do dia (`salas/{salaId}/attendance/{data}/votes`).

A otimização (OSRM /trip) é aplicada DENTRO de cada fase, preservando a
prioridade da rota (não mistura embarques com faculdades).

## 4. Múltiplos Endereços do Aluno
Tela `ManageAddressesPage` (rota `/manage-addresses`):
- Criar, listar, editar, excluir endereços (casa, trabalho, república...).
- Definir endereço padrão.
Armazenados em `users/{userId}/addresses/{addressId}`.

## 5. Seleção do Endereço na Chamada
Ao confirmar presença, o aluno informa: ida? volta? endereço de embarque?
endereço de desembarque? O endereço escolhido é gravado como snapshot no voto
(`boarding` / `dropoff`), então o sistema NUNCA usa o endereço padrão
automaticamente quando o aluno escolheu outro para aquele dia.

## 6. Informações ao Motorista
A chamada (`AttendanceOverviewPage`) e a rota exibem, por aluno: nome,
faculdade, endereço de embarque, endereço de desembarque e tipo de trajeto.

## 7. Regras Gerais
Aplicadas no `RouteBuilderService`: sem ausentes, sem faculdades vazias, sem
endereços não usados; agrupamento de faculdade; geração dinâmica.

## 8. Execução Automática da Rota
`ActiveRoutePage`:
- Avanço automático por geofence (raio configurável `_arrivalRadiusMeters`,
  padrão 40 m). Sem botão "Próximo".
- Confirmação de embarque/desembarque (Embarcou / Ausente / Pular; Desembarque
  realizado / Pular).
- Status de cada parada (aguardando / em andamento / concluída / ausente /
  cancelada).
- Próxima parada inteligente: nome, endereço ou nº de alunos, distância e ETA.
- Recálculo automático da rota a cada mudança + botão manual.
- Indicadores: transportados/total, concluídas, restantes, ausentes.
- Navegação externa (Google Maps / Waze) via `ExternalNavService`.

## Estrutura Firestore (novidades)
```
users/{userId}/addresses/{addressId}
  - id, label, logradouro, numero, complemento, bairro, cep, localidade, uf
  - latitude, longitude, isDefault

salas/{salaId}/attendance/{YYYY-MM-DD}/votes/{userId}
  - status (vaiEVolta|soIda|soVolta|naoVai), liberado, liberadoAt
  - userName, faculdadeId, faculdadeName, updatedAt
  - boarding: { addressId, label, shortAddress, latitude, longitude }
  - dropoff:  { addressId, label, shortAddress, latitude, longitude }
```

## Dependência adicionada
- `url_launcher: ^6.3.1` (abrir Google Maps / Waze)

## Como validar
1. `cd pi_van`
2. `flutter pub get`
3. `flutter analyze`
4. `flutter run`
