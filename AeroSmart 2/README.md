# AeroSmart ✈︎

**Despega sin pendientes.** App de aerolínea para pasajeros: buscas tu vuelo, eliges asiento con ayuda de un asistente, y antes de volar la app te va guiando con un checklist que se desbloquea según la hora, el clima del destino y tu pase de abordar.

Proyecto semestral de Desarrollo de Aplicaciones Móviles II (IEST) · Ana Sofia Soqui y Jacobo Castillo.

## Cómo correrlo

1. Abre `AeroSmart.xcodeproj` (Xcode 26).
2. Elige un simulador de iPhone (por ejemplo iPhone 17).
3. Cmd + R.

> Si ya tenías instalada una versión anterior en el simulador, bórrala primero (mantén presionado el ícono → Eliminar app). El modelo `User` cambió y la base de datos vieja no es compatible.

## Recorrido rápido

- **Entrar con la cuenta demo**, o crea tu cuenta en *Registro*.
- **Volar**: el saludo cambia según la hora. Elige origen y destino (el origen se queda guardado para la próxima vez), fecha y **Buscar vuelos**.
- Toca un vuelo y verás el **mapa de asientos**. Activa los filtros del **asistente de asiento** (Ventana, Pasillo, Más espacio, Salir rápido, Económico) y el asiento ideal empieza a brillar.
- **Reservar mi lugar** te lleva a **Mi Viaje**: pase de abordar con código de barras, cuenta regresiva, el **clima en tu destino** con un tip para la maleta y el checklist con progreso.
- Usa el **simulador de tiempo** para ver cómo cambia el estado del viaje (Check-in abierto, Abordando, En vuelo) y cómo se desbloquean las tareas.
- **En vivo**: elige un aeropuerto y mira el **tablero de salidas de hoy** (estatus real: a tiempo, retraso, en vuelo, cancelado) o el **radar** con los aviones que están volando cerca en este momento (altura, velocidad y hacia dónde van).
- **Viajes**: próximos e historial (desliza para cancelar o eliminar). **Perfil**: favoritos, token de Duffel y cerrar sesión.

## APIs que consume

| API | Para qué | Archivo |
|---|---|---|
| **Open-Meteo** (gratis, sin token) | Clima actual del destino | `ViewModels/WeatherViewModel.swift`, `Models/Weather.swift` |
| **Duffel** (modo prueba, con token) | Vuelos reales y mapa de asientos | `Services/DuffelClient.swift`, `FlightService.swift`, `SeatMapService.swift` |
| **OpenSky Network** (gratis, sin token) | Radar: aviones en el aire cerca del aeropuerto | `ViewModels/RadarViewModel.swift`, `Models/LiveAircraft.swift` |
| **Aviationstack** (llave gratis, 100 consultas al mes) | Estatus de las salidas de hoy | `ViewModels/DeparturesViewModel.swift`, `Models/FlightStatus.swift` |

Las dos siguen los mismos pasos de la clase 11: validar la URL con `guard`, armar el `URLRequest` (método, `Accept`, cabeceras), mandar con `URLSession.shared.data(for:)` + `await`, revisar el `statusCode` y decodificar con `JSONDecoder`. Como los JSON vienen en snake_case (`temperature_2m`, `total_amount`, `flight_status`), los campos se renombran con `CodingKeys`.

OpenSky es la excepción: manda cada avión como un arreglo con datos mezclados (texto, números, true/false), así que se lee con **codificación manual** (`JSONSerialization` + `[String: Any]`), igual que el "Extra" de la clase 11.

**Llave de Aviationstack:** crea una cuenta gratis en aviationstack.com, copia tu *Access Key* y pégala en Perfil. El plan gratis solo funciona por `http`, por eso el proyecto incluye `AeroSmart-Info.plist` con un permiso solo para `api.aviationstack.com` (iOS bloquea `http` si no se lo indicas). Para cuidar las 100 consultas del mes, la app solo vuelve a consultar cuando cambias de aeropuerto o tocas **Actualizar**.

**Token de Duffel:** crea una cuenta en duffel.com, activa el modo *Test*, genera un token (`duffel_test_...`) y pégalo en Perfil. Sin token, o si Duffel falla, la app usa vuelos y un mapa de demostración (A320, 30 filas) y lo avisa con un banner, así que nunca se queda sin funcionar. En modo prueba Duffel solo garantiza asientos para su aerolínea de pruebas (Duffel Airways).

## Qué temas de clase usa

- **TabView con `Tab`** (`MainTabView`).
- **`@AppStorage`**: sesión iniciada, último aeropuerto elegido (se comparte entre Volar y En vivo) y las llaves de Duffel y Aviationstack.
- **`@Observable` + `@MainActor`** en todos los ViewModels, creados con `@State` en la vista.
- **Patrón `Counter`** (Task + `Task.sleep` + `start()`/`stop()`): `TripClock` actualiza el estado del viaje cada 30 segundos.
- **`@Environment`** para compartir `AppState` entre pestañas.
- **`.task`** para llamar a las APIs al abrir una pantalla.
- **Botones con `Label` + `.glassProminent` / `.borderedProminent` + `.tint`**.
- SwiftData (`@Model`, `@Query`), `NavigationStack`, `ViewModifier`, alerts y `withAnimation`.

## Estructura

| Carpeta | Contenido |
|---|---|
| `Models` | `User`, `Trip`, `ChecklistItem`, `FavoriteDestination` (SwiftData) y `Airport`, `FlightOption`, `Seat`, `Weather`, `FlightStatus`, `LiveAircraft` |
| `ViewModels` | `AuthViewModel`, `FlightSearchViewModel`, `SeatSelectionViewModel`, `WeatherViewModel`, `RadarViewModel`, `DeparturesViewModel`, `TripClock`, `AppState` |
| `Services` | Cliente de Duffel y servicios de vuelos / asientos |
| `Views` | Pantallas y componentes |
| `Theme` | Paleta (fondo azul marino con morado), fondo, tarjetas, botón, código de barras |
| `Assets.xcassets` | Ícono de la app y `LogoMark` (isotipo en blanco para usar dentro de la app) |

## Pendientes

- Cambiar de asiento después de reservar.
- Notificaciones locales del checklist.
- Cifrar la contraseña antes de guardarla (en el avance se guarda tal cual en el teléfono).
- Guardar el token en Keychain; en producción, llamar a Duffel desde un servidor propio.
