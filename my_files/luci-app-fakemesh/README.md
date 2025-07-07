## Introducción a fakemesh

fakemesh es una estructura de topología de red compuesta por un `controlador (AC)`, uno o varios `AP cableados (Wired AP)` y `satélites (Agent)`. Es una red híbrida que combina los modos de red `Mesh inalámbrico` y `AC+AP`. En esta arquitectura, los `AP cableados` están conectados al `controlador (AC)` mediante cable de red, mientras que los `satélites (Agent)` se conectan de forma inalámbrica como clientes STA, formando conjuntamente una red de cobertura inalámbrica (que también puede incluir conexiones cableadas).

El despliegue de fakemesh es relativamente sencillo: solo necesitas conectar los dispositivos nodo a la red adecuada y configurar su rol, el Mesh ID y otros parámetros. Como fakemesh combina los modos Mesh inalámbrico y AC+AP, es muy fácil realizar una red híbrida, mejorando el alcance y la fiabilidad de la red.

Actualmente, [X-WRT](https://github.com/x-wrt/x-wrt) integra fakemesh de forma predeterminada.

## Uso de fakemesh

### Tras una configuración exitosa, las direcciones de acceso a los dispositivos son:

Acceso al controlador: `http://controller.fakemesh/` o `http://ac.fakemesh/`

Acceso a un AP: `http://{mac}.ap.fakemesh/` o `http://N.ap.fakemesh/`

Donde `{mac}` es la dirección MAC del AP (por ejemplo, `{mac}=1122334455AB`), y `N` es un número asignado automáticamente al AP (N=1, N=2, N=3, ...).

Ejemplo:
```
http://1.ap.fakemesh/
http://1122334455AB.ap.fakemesh/
```

### Resolución de problemas

Si un AP pierde la conexión durante unos 3 minutos, entra en modo de fallo. En este modo, se habilita un SSID por defecto, permitiendo que te conectes para reconfigurarlo.
El SSID y contraseña por defecto en modo de fallo son:
```
SSID: X-WRT_XXXX
CONTRASEÑA: 88888888
```

La IP de gestión del AP en modo de fallo será la puerta de enlace DHCP. Por ejemplo, si tu ordenador obtiene una IP `192.168.16.x`, la IP de gestión del AP será `192.168.16.1`.

## Componentes básicos de fakemesh

La red incluye un `controlador (controller)` y uno o varios `AP`.

Los AP pueden ser: `satélites (Agent)` o `AP cableados (Wired AP)`.

**Controlador (Controller):** Actúa como AC y router principal, proporcionando salida a Internet y gestión centralizada de los satélites y AP cableados, así como de la configuración inalámbrica.

**Satélite (Agent):** AP que se conecta a la red mediante Wi-Fi.

**AP cableado (Wired AP):** AP que se conecta a la red mediante cable de red.

## Parámetros de configuración de fakemesh

### 1. Mesh ID

   Este parámetro es el ID común de la red fakemesh; debe ser igual en el controlador, satélites y AP cableados.

### 2. Clave (Key)

   Es la clave compartida de la red. Se utiliza para cifrado; si no deseas cifrado puedes dejarlo en blanco.

### 3. Banda (Band)

   Es la banda inalámbrica utilizada (2G o 5G). Todos los nodos deben estar configurados en la misma banda.

### 4. Rol (Role)

   Puede ser controlador, satélite o AP cableado.

### 5. Configuración sincronizada (Sync Config)

   Indica si la configuración Wi-Fi se gestiona de forma centralizada desde el controlador.

### 6. Dirección IP de acceso (Access IP address)

   Permite asignar una IP específica al controlador para acceder a su interfaz de gestión.

### 7. Desactivar Fronthaul (Fronthaul Disabled)
   Si se activa, este nodo no permitirá que otros AP se conecten mediante su Wi-Fi.

### 8. Componente de itinerancia (Band Steer Helper)
   Actualmente se puede elegir entre [DAWN](https://github.com/fakemesh/dawn) o [usteer](https://github.com/fakemesh/usteer) como asistentes de itinerancia.

## Gestión inalámbrica

   Desde la interfaz del controlador se puede gestionar toda la red inalámbrica: añadir o eliminar SSID, establecer cifrado y ancho de banda, etc.

## Despliegue del controlador en modo “bypass” (no como gateway)

   Si el controlador no actúa como puerta de enlace ni proporciona DHCP, deberás configurar manualmente la red: asignar IP LAN, puerta de enlace y DNS al controlador. Por defecto, el puerto LAN del controlador será cliente DHCP y obtendrá IP de un gateway externo. Si prefieres IP estática, asegúrate de que el controlador y el gateway estén en la misma subred y puedan comunicarse entre sí. Si no es así, no será posible sincronizar la configuración entre el controlador y los AP.
