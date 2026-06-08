# VanGo — Guia Completo do App

> Projeto Integrador Senac — App de gestão de van escolar  
> Desenvolvido com Flutter + Firebase

---

## Índice

1. [O que o app faz](#o-que-o-app-faz)
2. [Como os testadores instalam](#como-os-testadores-instalam)
3. [Fluxo completo de uso](#fluxo-completo-de-uso)
4. [O que está implementado](#o-que-está-implementado)
5. [Limitações conhecidas](#limitações-conhecidas)
6. [Como gerar novas versões](#como-gerar-novas-versões)
7. [Estrutura técnica](#estrutura-técnica)

---

## O que o app faz

O VanGo é um app para gerenciar vans escolares universitárias. Tem dois perfis:

- **Motorista** — cria salas, gerencia alunos, monta rotas otimizadas, navega com GPS
- **Aluno** — marca presença diária, informa se vai e volta, marca quando está liberado da faculdade, acompanha a van no mapa

---

## Como os testadores instalam

### Android (APK)

1. Acessa o link do Google Drive que você vai compartilhar
2. Baixa o arquivo `.apk`
3. Abre o arquivo — o Android vai pedir para ativar **"Instalar apps de fontes desconhecidas"**
4. Ativa nas configurações e instala normalmente
5. O ícone do VanGo aparece na tela inicial

> **Como o testador sabe que é seguro?**  
> O link vai vir diretamente de você pelo grupo/WhatsApp. É o mesmo processo que qualquer app beta — só instala quem recebe o link da Gabi.

---

### iOS (PWA — funciona como app)

O iOS **não aceita APK**. A solução é o PWA — um site que se comporta como app nativo.

**Passo a passo para o testador iOS:**

1. Abre o link do VanGo no **Safari** (obrigatório — não funciona no Chrome nem Firefox)
2. Toca no botão de compartilhar (quadrado com seta pra cima, na barra inferior)
3. Rola a lista e toca em **"Adicionar à Tela de Início"**
4. Confirma o nome "VanGo" e toca em **"Adicionar"**
5. O ícone aparece na tela inicial igual a um app normal
6. Abre pelo ícone — abre em tela cheia sem barra do navegador

> **Diferença do PWA vs app nativo:**  
> Precisa de internet para funcionar (não fica salvo offline).  
> Notificações em background não funcionam no iOS via PWA.  
> Todo o resto funciona normalmente.

---

## Fluxo completo de uso

### Configuração inicial (motorista faz uma vez)

```
1. Motorista cria conta → escolhe "Motorista"
2. Vai em "Salas" → cria uma sala (ex: "Van Manhã")
3. Compartilha o código de 6 letras com os alunos
4. Vai em "Faculdades" → adiciona as faculdades pelo CEP
   (o app busca o endereço automaticamente pelo ViaCEP + coordenadas pelo Nominatim)
```

### Configuração inicial (aluno faz uma vez)

```
1. Aluno cria conta → escolhe "Estudante"
2. Vai em "Entrar em sala" → digita o código do motorista
3. Vai no perfil → seleciona sua faculdade
4. Vai em "Meus Endereços" → cadastra endereço de casa
   (pode ter vários: casa, trabalho, república...)
```

---

### Dia a dia — Rota de Ida (manhã)

**Aluno:**
```
Antes da van sair:
1. Abre o VanGo → aba "Início"
2. Toca em "Vou e Volto" (ou "Só Ida")
3. Seleciona o endereço de embarque (de onde vai ser buscado)
4. Confirma → chamada salva
```

**Motorista:**
```
1. Abre o VanGo → Dashboard mostra quantos confirmaram
2. Vai em "Montar Rota" → seleciona "Ida"
3. Vê a lista de paradas (casas dos alunos + faculdades)
4. Toca "Otimizar" → o app calcula o melhor trajeto considerando
   a localização atual do motorista como ponto de partida
5. Confirma → toca "Iniciar"
6. Na tela de navegação:
   - Mapa gira na direção do movimento
   - Banner no topo mostra próxima curva ("Em 300m, vire à direita")
   - Ao chegar a 300m de uma parada → modal abre automaticamente
   - Registra embarque ou marca ausente
7. Toca "Navegar" para abrir Google Maps com todas as paradas
   (Google Maps mostra trânsito em tempo real)
```

**Aluno durante a rota:**
```
- Recebe notificação quando a van está a 300m de casa
- Pode ver a van no mapa em tempo real (aba "Mapa")
```

---

### Dia a dia — Rota de Volta (tarde/noite)

**Aluno:**
```
Quando a aula acabar e estiver liberado para ir embora:
1. Abre o VanGo → aba "Início"
2. Toca em "Estou liberado"
3. O motorista é notificado imediatamente (som + notificação visual)
```

**Motorista:**
```
1. Vai em "Montar Rota" → seleciona "Volta"
   (só aparecem alunos que já estão liberados)
2. Otimiza e inicia a rota
3. À medida que mais alunos ficam liberados DURANTE a rota:
   - App recebe o evento em tempo real
   - Fala em voz alta: "Maria liberada"
   - Mostra snackbar: "Maria liberada! Rota atualizada. [Navegar]"
   - Rota é recalculada automaticamente com a nova parada
   - Motorista toca "Navegar" para reabrir Google Maps com a rota atualizada
4. Ao chegar à faculdade:
   - Se TODOS os alunos daquela faculdade estiverem liberados → modal abre
   - Se ainda tem aluno pendente → aviso "Aguardando 1 aluno em [Faculdade]"
   - Quando o último libera → modal abre automaticamente
```

---

## O que está implementado

### Autenticação
- [x] Cadastro com validação de email (formato verificado antes de enviar)
- [x] Telefone com máscara automática `(XX) XXXXX-XXXX`
- [x] Cadastro de endereço via CEP (preenchimento automático)
- [x] Geocoding do endereço (coordenadas GPS salvas automaticamente)
- [x] Login / Logout
- [x] Recuperação de senha por email

### Motorista
- [x] Criar e gerenciar múltiplas salas
- [x] Compartilhar código de acesso com alunos
- [x] Dashboard com contadores em tempo real (confirmados, pendentes, liberados)
- [x] Lista de liberações do dia com nome e faculdade
- [x] Gerenciar faculdades (adicionar, editar, remover por CEP)
- [x] Montar rota de ida e volta
- [x] Otimização de rota via OSRM (TSP) partindo da parada mais próxima ao motorista
- [x] Navegação ativa com mapa girando na direção do movimento
- [x] Banner de instrução de curva em tempo real
- [x] Geofence automático: modal abre ao chegar a 300m da parada
- [x] Registrar embarque, desembarque, ausência ou pular parada
- [x] Compartilhamento de localização GPS com os alunos
- [x] Abrir Google Maps com todas as paradas pendentes
- [x] Abrir Waze na próxima parada
- [x] Notificação sonora + visual quando aluno é liberado (com nome falado em voz)
- [x] Rota de volta: só mostra alunos já liberados
- [x] Rota de volta: adiciona alunos liberados em tempo real e recalcula
- [x] Rota de volta: aguarda todos os alunos da faculdade serem liberados antes de confirmar parada

### Aluno
- [x] Participar de múltiplas salas
- [x] Seletor de sala ativa
- [x] Sair de sala
- [x] Chamada diária: vou e volto / só ida / só volta / não vou
- [x] Selecionar endereço de embarque e desembarque por dia
- [x] Múltiplos endereços cadastrados (casa, república, trabalho...)
- [x] Marcar "Estou liberado" para a rota de volta
- [x] Ver localização da van em tempo real no mapa
- [x] Notificação quando a van está a 300m de casa ou da faculdade
- [x] Lembrete de chamada no app (aparece após as 6h se não marcou)

### Qualidade e estabilidade
- [x] Validação de email no cadastro
- [x] Máscara de telefone no cadastro
- [x] Otimização de rota sempre usa a ordem canônica do servidor (não a reordenação manual)
- [x] Reconstrução correta de ordem OSRM para rotas com 5+ paradas
- [x] Notificações filtradas por sessão (sem renotificar dados antigos ao abrir o app)
- [x] Snackbar "aguardando na faculdade" não repete enquanto motorista está parado
- [x] Proteção contra crash se nome do usuário vier vazio

---

## Limitações conhecidas

| Limitação | Motivo | Impacto |
|---|---|---|
| Notificações só funcionam com o app aberto | Requer Firebase Blaze (pago) para Cloud Functions | Baixo — motorista usa o app durante a rota |
| Lembrete de chamada só aparece no app | Mesma razão acima | Baixo — aluno abre o app pra marcar de qualquer forma |
| iOS não recebe notificações em background | Requer Apple Developer ($99/ano) + APNs | Médio — impacta alunos iOS |
| Waze só navega para a próxima parada | Waze não suporta multi-parada na URL | Baixo — driver usa Google Maps |
| Google Maps não atualiza automaticamente | Impossível forçar app externo a atualizar | Baixo — tem botão "Navegar" no snackbar |
| GPS de voz (TTS) só funciona com app aberto | Limitação do sistema operacional | Baixo — motorista está usando o app |
| Precisão do geocoding varia | Nominatim (OpenStreetMap) tem menos dados que Google | Médio — fallback por bairro/cidade |

---

## Como gerar novas versões

Toda vez que fizer uma mudança no código e quiser distribuir:

### 1. Gerar APK (Android)
```powershell
cd C:\Users\Gabi\Documents\pi-van\pi_van
flutter build apk --release
```
Arquivo gerado: `build\app\outputs\flutter-apk\app-release.apk`  
Sobe no Google Drive e manda o novo link.

### 2. Atualizar PWA (iOS)
```powershell
cd C:\Users\Gabi\Documents\pi-van\pi_van
flutter build web --no-tree-shake-icons
firebase deploy --only hosting
```
O link `https://app-de-van-5f05d.web.app` já atualiza automaticamente.  
Quem tinha o PWA instalado no iPhone abre e recebe a versão nova na próxima vez.

---

## Estrutura técnica

| Camada | Tecnologia |
|---|---|
| Frontend | Flutter (Dart) |
| Autenticação | Firebase Auth |
| Banco de dados | Cloud Firestore |
| Hospedagem web | Firebase Hosting |
| Mapas | OpenStreetMap via flutter_map |
| Roteamento / Otimização | OSRM (gratuito, sem API key) |
| Geocoding | Nominatim + ViaCEP |
| Notificações locais | flutter_local_notifications |
| Voz (TTS) | flutter_tts |
| Navegação externa | Google Maps / Waze (via URL) |
| Arquitetura | Clean Architecture (domain / data / presentation) |
| Injeção de dependência | get_it |

### Estrutura Firestore
```
users/{userId}
  ├── name, email, phone, role
  ├── logradouro, bairro, cidade, uf, cep
  ├── latitude, longitude
  ├── salaId (sala ativa)
  ├── salaIds[] (todas as salas)
  ├── faculdadeId, faculdadeName
  └── addresses/ (subcoleção)
      └── {addressId} → label, endereço, lat, lng

salas/{salaId}
  ├── name, accessCode, driverId
  ├── students/ (subcoleção)
  │   └── {userId} → name, faculdadeId, lastProximityNotifAt
  ├── faculdades/ (subcoleção)
  │   └── {facId} → name, address, latitude, longitude
  ├── attendance/ (subcoleção)
  │   └── {date}/votes/{userId}
  │       → status, userName, liberado, liberadoAt,
  │         boarding{}, dropoff{}, faculdadeId, faculdadeName
  └── driverLocation/current
      → latitude, longitude, isSharing, timestamp
```
