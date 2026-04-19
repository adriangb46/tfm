# UI Screens Reference

> Single source of truth for all frontend screens and modals.
> Before creating or modifying any Angular component, read the relevant screen entry here.
> Do NOT implement behaviour that is not described in this file without asking the user first.

---

## Screen Map (navigation overview)

```
(no session)
  ├── signUp
  └── signIn
        │
        ▼
      lobby ──────────────────────────────────────────────────────┐
        ├── [modal] crearPartida                                  │
        ├── [modal] unirsePartida                                 │
        ├── [nav] personajes (info page)                          │
        ├── [nav] reglas (info page)                              │
        ├── [user menu] userConfig                                │
        │     └── [modal] cambiarContraseña                       │
        ├── [user menu] estadísticas (user-level)                 │
        └── [user menu] adminPage (admin only)                    │
                                                                  │
      lobbyPrevia (waiting room) ───────────────────────────────► │
                                                                  │
      gamePage ◄────────────────────────────────────────────────-─┘
        ├── [modal] tropas (trained troops)
        ├── [modal] entrenarTropas
        ├── [modal] arbolTecnologico
        │     └── [modal] modalTecnologia
        ├── [modal] log
        └── [modal] atacar
              └── [modal] añadirTropaAtaque
```

---

## 1. signUp

**Route:** `/signup`
**Angular component:** `SignUpComponent`
**Prerequisites:** No active session. User not registered.

### Layout elements
- Game title / thematic header
- Section title: "Register" / "Sign Up"
- Input: username (`placeholder: 'Tu nombre de usuario'`)
- Input: password (`placeholder: 'Tu secreto guardado'`, type password)
- Input: repeat password (`placeholder: 'Tu secreto guardado y confirmado'`, type password)
- Primary CTA button: "REGISTRARSE"
- Secondary link: "INICIAR SESIÓN" → navigates to `/signin`

### Actions & results
| Action | Result |
|--------|--------|
| Fill all fields + click "REGISTRARSE" | Account created, session started, redirect to `/lobby` |
| Username already exists | Show inline error under username field |
| Passwords do not match | Show inline error under repeat-password field |

### Notes
- The "close / VOLVER A LA SOMBRA" button in the mockup: navigates back (browser history or `/`).

---

## 2. signIn

**Route:** `/signin`
**Angular component:** `SignInComponent`
**Prerequisites:** No active session. User already registered.

### Layout elements
- Game title / thematic header
- Section title: "Sign In" / "Iniciar sesión"
- Input: username
- Input: password (type password)
- Primary CTA button: "INICIAR SESIÓN"
- Secondary link: "CREAR UNA CUENTA" → navigates to `/signup`

### Actions & results
| Action | Result |
|--------|--------|
| Fill fields + click button | Session started, redirect to `/lobby` |
| Wrong credentials | Show inline error message |

---

## 3. lobby

**Route:** `/lobby`
**Angular component:** `LobbyComponent`
**Prerequisites:** Active session.

### Layout elements
- Top navigation bar: `Home` | `Lobby` | `Personajes` | `Reglas`
- User menu icon (top right) with dropdown: `Config` | `Estadísticas` | `Admin` (admin only) | `Salir`
- Hero section with two buttons: `Nueva Partida` | `Unirse a Partida`
- Section "Partidas activas": list of active games, each row has:
  - Game info (name / code / clan)
  - Button `Entrar`
  - Button `Salir` (abandon game — shows confirmation modal before executing)
- Section "Partidas terminadas" (collapsible `▽`): list of finished games, each row has:
  - Game info
  - Button `Estadísticas`
  - Button `Borrar` (removes from this user's view only; game not deleted on server)

### Actions & results
| Action | Result |
|--------|--------|
| `Home` | Redirect to home page |
| `Lobby` | Reload lobby (current page) |
| `Personajes` | Navigate to clan info page |
| `Reglas` | Navigate to game rules page |
| `Nueva Partida` | Open modal `crearPartida` |
| `Unirse a Partida` | Open modal `unirsePartida` |
| `Entrar` (active game) | Navigate to `gamePage` for that game |
| `Salir` (active game) | Show confirmation modal → on confirm: abandon game (player loses) |
| `Estadísticas` (finished game) | Navigate to `estadísticas` for that game |
| `Borrar` (finished game) | Remove game from this user's list (server record kept) |
| `Config` (user menu) | Navigate to `userConfig` |
| `Estadísticas` (user menu) | Navigate to global `estadísticas` for this user |
| `Admin` (user menu) | Navigate to `adminPage` (only shown if user is admin) |
| `Salir` (user menu) | Log out → redirect to `/signin` |

---

## 4. crearPartida (modal)

**Trigger:** `Nueva Partida` button in lobby
**Angular component:** `CrearPartidaModalComponent`
**Prerequisites:** Active session.

### Layout elements
- Title: "JURAMENTAR CLAN" / "Crear Partida"
- Grid of clan cards (up to 6 slots, one per available clan) — each card shows clan icon + name
- Player selects ONE clan for their character
- Primary CTA button: "CREAR PARTIDA"

### Actions & results
| Action | Result |
|--------|--------|
| Select clan + click "CREAR PARTIDA" | Game created on server; unique hash code generated; code shown in a modal overlay on top of `gamePage` (user is redirected to `lobbyPrevia`) |
| Click outside / close | Modal closes, back to lobby |

### Notes
- The game code is generated server-side (salted hash). The frontend only displays it.
- After creation the user is the **host** (anfitrión).

---

## 5. unirsePartida (modal)

**Trigger:** `Unirse a Partida` button in lobby
**Angular component:** `UnirsePartidaModalComponent`
**Prerequisites:** Active session. A game must exist with the code entered.

### Layout elements
- Title: "UNIRSE AL FRENTE"
- Subtitle: "Presentad el código sagrado de la batalla"
- Label: "CÓDICE DE BATALLA"
- Input: game code (`placeholder: 'Introduce el Código'`)
- Clan selector: shows only clans NOT already chosen in that game (unlocked after code is entered and validated)
- Primary CTA button: "ENTRAR EN COMBATE"

### Actions & results
| Action | Result |
|--------|--------|
| Enter valid code → clan list loads | Shows only available clans |
| Select clan + click "ENTRAR EN COMBATE" | Joined game → redirect to `lobbyPrevia` |
| Game is full | Show error modal: "La partida está llena" |
| Invalid code | Show inline error under code input |

---

## 6. lobbyPrevia (waiting room)

**Route:** `/lobby-previa`
**Angular component:** `LobbyPreviaComponent`
**Prerequisites:** Active session + created or joined a game.

### Layout elements
- Game code displayed prominently (so host can share it)
- Player list (bullet list, updates in real time via Socket.IO)
- Error text line below player list (e.g. "Se necesitan al menos 2 jugadores")
- Button "INICIAR PARTIDA"
  - **Host:** enabled when player count is between 2 and 6
  - **Non-host:** always disabled

### Actions & results
| Action | Result |
|--------|--------|
| Host clicks "INICIAR PARTIDA" with valid player count | All players redirected to `gamePage` |
| Host clicks with < 2 players | Error message shown below player list |
| Non-host waits | Button is visible but disabled; redirected automatically when host starts |

### Notes
- Player list updates via Socket.IO push. No polling.

---

## 7. gamePage (battle screen)

**Route:** `/game`
**Angular component:** `GamePageComponent`
**Prerequisites:** Active session + game created + player is in that game.

### Layout elements
- Top bar (left): back arrow `←` + clan logo
- Top bar (center): phase indicator (`Fase`)
  - Sub-info: `Vida` (capital health) | `Dinero` (economic credits) | `Ptos. Inv.` (research credits)
- Top bar (right): button `Abandonar`
- Main area: territory map showing all players' territories as organic shapes (clickable to attack)
- Right sidebar (vertical):
  - Button `Entrenar Tropas` → opens modal `entrenarTropas`
  - Button `Tropas` → opens modal `tropas`
  - Button `Árbol Tecnológico` → opens modal `arbolTecnologico`
  - Button `Log` → opens modal `log`

### Actions & results
| Action | Result |
|--------|--------|
| Click on enemy territory | Open modal `atacar` targeting that player |
| Click own territory | No action (or show own stats — TBD) |
| Click `Entrenar Tropas` | Open modal `entrenarTropas` |
| Click `Tropas` | Open modal `tropas` |
| Click `Árbol Tecnológico` | Open modal `arbolTecnologico` |
| Click `Log` | Open modal `log` |
| Click `←` | Navigate back to `/lobby` |
| Click `Abandonar` | Abandon game (player loses) — show confirmation modal first |

### Notes
- During **Preparation phase**: clicking enemy territories is disabled (no attacks allowed).
- All state (phase, health, credits) arrives via Socket.IO push, never fetched by the frontend.

---

## 8. modal — tropas (trained troops)

**Trigger:** `Tropas` button in `gamePage` sidebar
**Angular component:** `TropasModalComponent`
**Prerequisites:** Active session + in game.

### Layout elements
- Title: "TROPAS"
- Close button `✕`
- List of trained troops, each row:
  - Troop name
  - Quantity (grouped by type)
  - Progress bar:
    - If training not complete: shows training progress
    - If training complete: shows health bar (= currentPoints / maxPoints)

### Notes
- Troops still training and troops ready are shown together.
- One visual item per troop instance (repeats allowed if multiple of same type).

---

## 9. modal — entrenarTropas (train troops)

**Trigger:** `Entrenar Tropas` button in `gamePage` sidebar
**Angular component:** `EntrenarTropasModalComponent`
**Prerequisites:** Active session + in game.

**Note for the AI:** also check `front_color_guide.md` for the viking color palette before styling this modal, when available.

### Layout elements
- Title: "ENTRENAR"
- Shows current economic credits (`Ptos.`)
- Close button `✕`
- List of available troop types for the player's clan, each row:
  - Troop name
  - Cost (`apCost`)
  - Button `Entrenar`

### Actions & results
| Action | Result |
|--------|--------|
| Click `Entrenar` with sufficient credits | Troop enters training queue; visible in `tropas` modal with progress bar |
| Click `Entrenar` with insufficient credits | Button disabled or inline error |
| Troop requires unresearched tech | Row shown as locked / greyed out |

---

## 10. modal — arbolTecnologico (tech tree)

**Trigger:** `Árbol Tecnológico` button in `gamePage` sidebar
**Angular component:** `ArbolTecnologicoModalComponent`
**Prerequisites:** Active session + in game.

### Layout elements
- Title: tech tree name
- Shows current research credits (`Ptos. Inv.`)
- Close button
- Visual tree graph of research nodes (from `clans.yml` for the player's clan):
  - Nodes connected by lines showing prerequisites
  - Each node shows: name, cost, research time
  - Node states:
    - **Locked** (greyed): prerequisite not researched
    - **Available** (normal): prerequisite met, can research
    - **In progress**: background fill showing research progress %
    - **Completed**: visually distinct (e.g. gold border)

### Actions & results
| Action | Result |
|--------|--------|
| Click on any node | Open modal `modalTecnologia` for that node |

---

## 11. modal — modalTecnologia (single tech detail)

**Trigger:** Clicking a node in `arbolTecnologico`
**Angular component:** `ModalTecnologiaComponent`
**Prerequisites:** Active session + in game + tech tree open.

### Layout elements
- Close button `✕`
- Tech name
- Description text
- Cost and research time
- Button `Investigar`

### Actions & results
| Action | Result |
|--------|--------|
| Click `Investigar` with sufficient research credits | Research starts; progress visible in tech tree node |
| Click `Investigar` with insufficient credits | Button disabled or inline error |
| Tech already researched or in progress | Button disabled |

---

## 12. modal — log

**Trigger:** `Log` button in `gamePage` sidebar
**Angular component:** `LogModalComponent`
**Prerequisites:** Active session + in game.

### Layout elements
- Title: "LOG"
- Close button `✕`
- Scrollable list of game events (battle results, phase changes, troop arrivals, etc.)
- Events ordered chronologically, newest last (or newest first — TBD)

### Notes
- Log entries arrive via Socket.IO. The modal shows accumulated events since game start.

---

## 13. modal — atacar (attack)

**Trigger:** Clicking an enemy territory on the game map
**Angular component:** `AtacarModalComponent`
**Prerequisites:** Active session + in game + War or End phase.

### Layout elements
- Title: "ATACAR A [enemy name]"
- Close button `✕`
- List of troops already added to the attack (each row has a remove `✕` button)
- Button `+` → opens modal `añadirTropaAtaque`
- Primary CTA button: `ATACAR`

### Actions & results
| Action | Result |
|--------|--------|
| Click `+` | Open modal `añadirTropaAtaque` |
| Click `✕` on a troop row | Remove that troop from the attack |
| Click `ATACAR` with troops selected | Attack launched → troops dispatched → modal closes |
| Click `ATACAR` with no troops | Button disabled or error |

---

## 14. modal — añadirTropaAtaque (add troop to attack)

**Trigger:** `+` button inside `atacar` modal
**Angular component:** `AñadirTropaAtaqueModalComponent`
**Prerequisites:** Active session + in game + `atacar` modal open.

### Layout elements
- Title: "Tropas disponibles"
- Grid/list of available (deployed=false, training complete) troops
- Button `Cancelar`

### Actions & results
| Action | Result |
|--------|--------|
| Click a troop | Troop added to the attack list in `atacar` modal → this modal closes |
| Click `Cancelar` | Modal closes, back to `atacar` modal |

### Notes
- Only troops with `deployed=false` and training complete are shown here.
- Troops already in training or already deployed are not listed.

---

## 15. estadísticas

**Route:** `/stats/user` (global) or `/stats/game` (current game)
**Angular component:** `EstadisticasComponent`
**Prerequisites:** Active session + accessed from lobby or user menu.

### Layout elements
- Navigation bar (inherited from lobby)
- Stats panel with:
  - A main bar/chart at the top
  - Rows of stat items (label + value bar)

### Notes
- Data source: MongoDB analytics (served via DB Server REST → Middle → Frontend).
- Exact stats to display are TBD — to be defined when the analytics API is implemented.

---

## 16. userConfig

**Route:** `/config`
**Angular component:** `UserConfigComponent`
**Prerequisites:** Active session + accessed via user menu → Config.

### Layout elements
- Navigation bar
- Avatar selector (circular avatar display)
- Input: display name / username
- Input: email
- Button `Clave` → opens modal `cambiarContraseña`
- Dropdown: language selector (e.g. `ES ▼`)
- Buttons: `Guardar` | `Cancelar`

### Actions & results
| Action | Result |
|--------|--------|
| Change fields + click `Guardar` | Changes saved to server |
| Click `Cancelar` | Changes discarded, back to previous state |
| Click `Clave` | Open modal `cambiarContraseña` |

---

## 17. modal — cambiarContraseña

**Trigger:** `Clave` button in `userConfig`
**Angular component:** `CambiarContraseñaModalComponent`
**Prerequisites:** Active session + on `userConfig` page.

### Layout elements
- Close button `✕`
- Input: current password
- Input: new password
- Input: repeat new password
- Buttons: `Guardar` | `Cancelar`

### Actions & results
| Action | Result |
|--------|--------|
| Fill all + click `Guardar` | Password changed |
| New passwords don't match | Inline error |
| Wrong current password | Inline error from server |
| Click `Cancelar` | Modal closes |

---

## 18. adminPage

**Route:** `/admin`
**Angular component:** `AdminPageComponent`
**Prerequisites:** Active session + user has admin role. Button only shown in user menu if admin.

### Layout elements
- Navigation bar
- Left panel: list or search of users
- Right panel:
  - Chart / graph: global game statistics
  - Section "Baneos": table of banned users
  - Search bar: `🔍 Buscar`

### Actions & results
| Action | Result |
|--------|--------|
| Search user + ban action | User banned (cannot log in) |
| View stats chart | Displays global game analytics |

### Notes
- If the user is not admin, the `Admin` option does not appear in the user menu. Navigating to `/admin` directly redirects to `/lobby`.
