# brudalevante-openwrt-banana-pi-r4

## Compilación automática de OpenWrt para Banana Pi R4

Este repositorio permite construir una imagen OpenWrt personalizada para el Banana Pi R4 de forma totalmente automática, incluyendo los últimos parches y paquetes para un funcionamiento correcto del hardware y la WiFi.

---

### **Requisitos previos**

- Sistema Linux (recomendado Ubuntu/Debian)
- Dependencias de compilación de OpenWrt instaladas ([ver docs oficiales](https://openwrt.org/docs/guide-developer/build-system/install-buildsystem#installing-required-packages))
- Al menos 40 GB de espacio libre (se recomienda más para builds frecuentes)
- Conexión a Internet estable

---

### **Pasos para compilar**

1. **Clonar este repositorio:**
   ```sh
   git clone https://github.com/brudalevante/brudalevante-openwrt-banana-pi-r4.git
   cd brudalevante-openwrt-banana-pi-r4
   ```

2. **Dar permisos de ejecución al script (solo la primera vez):**
   ```sh
   chmod +x bpi-r4-openwrt-builder.sh
   ```

3. **Editar la configuración si quieres cambiar versión de kernel o hash de OpenWrt:**
   - Cambia el hash de OpenWrt o de los feeds en el propio script (`bpi-r4-openwrt-builder.sh`)
   - Modifica la línea `CONFIG_KERNEL_PATCHVER=...` en tu archivo de configuración (`configs/rc1_ext_mm_config`) para seleccionar la versión de kernel deseada.

4. **Ejecutar el script:**
   ```sh
   ./bpi-r4-openwrt-builder.sh
   ```

---

### **¿Qué hace este script?**

- Borra los directorios previos de compilación (`openwrt`, `mtk-openwrt-feeds`) para asegurar builds limpias.
- Clona el código fuente de OpenWrt y los feeds de MediaTek en los hashes especificados (puedes editarlos para cambiar versión).
- Aplica todos los parches y reglas personalizadas desde `my_files`.
- Copia tu configuración predefinida (`.config`).
- Instala y añade paquetes personalizados, incluyendo `luci-app-3ginfo-lite`, `luci-app-at-socat`, `luci-app-fakemesh`, `luci-app-modemband`, etc.
- Compila la imagen usando todos los núcleos disponibles.
- Muestra al final la información del kernel y los kmods incluidos.
- Los binarios generados aparecen en `openwrt/bin/targets/`.

---

### **Notas importantes**

- **Feeds MediaTek:** Se usan los feeds de MediaTek (`mtk-openwrt-feeds`) porque incluyen los últimos parches y drivers para el Banana Pi R4 y su WiFi.  
- **`my_files`:** Este directorio contiene parches y paquetes imprescindibles. Si faltan archivos, la build puede fallar o funcionar mal (especialmente la WiFi).
- **Cambio de kernel y hash:** Puedes compilar cualquier kernel soportado cambiando el hash de OpenWrt y el valor de `CONFIG_KERNEL_PATCHVER` en el archivo de configuración.  
- **Paquetes personalizados:** Si quieres añadir/quitar paquetes, edítalo en tu archivo `.config` y/o añade los directorios en `my_files`.
- **Build limpia:** Siempre se borra todo al empezar (puedes comentar los `rm -rf` si quieres conservar fuentes para builds más rápidas, pero no es lo recomendado).
- **Problemas con la WiFi:** Asegúrate de tener todos los parches de `my_files` correctamente copiados.
- **luci-app-fakemesh** se instala automáticamente desde `my_files` si está presente.

---

¡Feliz hackeo y que disfrutes tu build para el Banana Pi R4!
