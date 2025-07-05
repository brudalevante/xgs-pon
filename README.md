# brudalevante-openwrt-banana-pi-r4

## Compilación automática de OpenWrt para Banana Pi R4

Este repositorio permite construir una imagen OpenWrt personalizada para el Banana Pi R4 de forma completamente automática, sin intervención manual.

---

### **Requisitos previos**

- Sistema Linux (recomendado Ubuntu/Debian)
- Dependencias de compilación de OpenWrt instaladas ([ver docs oficiales](https://openwrt.org/docs/guide-developer/build-system/install-buildsystem#installing-required-packages))
- Al menos 40 GB de espacio libre

---

### **Pasos para compilar**

1. **Clona este repositorio**  
   Si aún no lo has hecho:
   ```sh
   git clone https://github.com/brudalevante/brudalevante-openwrt-banana-pi-r4.git
   cd brudalevante-openwrt-banana-pi-r4
   ```

2. **(Solo la primera vez) Da permisos de ejecución al script:**
   ```sh
   chmod +x build_openwrt_auto.sh
   ```

3. **Ejecuta el script automático:**
   ```sh
   ./build_openwrt_auto.sh
   ```

   El script descargará, aplicará todos los parches y configuraciones, y compilará la imagen usando tu `.config` personalizado de `configs/rc1_ext_mm_config`.

---

### **¿Qué hace este script?**

- Descarga el código fuente de OpenWrt y los feeds de MediaTek en las versiones especificadas.
- Aplica todos los parches y reglas personalizadas.
- Añade tus paquetes y aplicaciones personalizados (luci-app, parches, etc).
- Copia tu configuración predefinida (`.config`).
- Compila la imagen de forma totalmente automática (sin menús ni intervención manual).

---

### **¿Dónde encuentro la imagen compilada?**

Una vez termine el proceso, encontrarás el firmware y archivos generados en:

```
openwrt/bin/targets/
```

---

### **Notas importantes**

- Si quieres cambiar los paquetes incluidos, edita tu archivo `.config` en `configs/rc1_ext_mm_config` y vuelve a ejecutar el script.
- Si el script da error por falta de espacio, dependencias o rutas, revisa los mensajes de error y asegúrate de cumplir todos los requisitos previos.
- Si tienes dudas o problemas, abre un issue en este repositorio.

---

¡Feliz hackeo!  
