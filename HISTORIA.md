# Historia del juego

## El Censo de las Tres Ecosferas

### Premisa general
Nahara, la última cronista de la Orden de los Acordantes, despierta tras el cataclismo astral que silenció los obeliscos del Volcán Inferno, la Nieve Hileo y los Pantanos Sombríos. Cada región quedó encapsulada dentro de una ecosfera muda y sólo puede reactivarse recuperando reliquias sonoras: cristales de magma (armónicos graves), gemas glaciares (melodías medias) y monedas-eco de brea (agudos chispeantes). El HUD funciona como su partitura viva: cada recurso sumado en el inventario acerca a Nahara a recomponer la sinfonía que estabiliza el mundo.

### Progresión narrativa
1. **Acto I – Volcán Inferno: «Compás del Yunque».** Los ríos de lava distorsionan la visión. Cada cristal de magma recogido se convierte en una nota enfriante que detiene temporalmente las coladas ardientes y permite acceder a cámaras secundarias. El jugador debe coordinar sus desplazamientos para evitar el daño térmico mientras persigue el ritmo marcado por el contador de recursos.
2. **Acto II – Nieve Hileo: «Contracanto del Hálito».** El hielo acelera y desliza los pasos de Nahara. Las gemas glaciares cuelgan dentro de cristales resonantes que requieren impulso y precisión. Cada captura completa fragmentos de la melodía helada y se registra inmediatamente en el panel de inventario, reforzando la idea de una partitura en reconstrucción.
3. **Acto III – Pantanos Sombríos: «Fuga del Murmullo».** El veneno del lodo corrompe lentamente su resistencia. Las monedas-eco de brea vibran en charcas tóxicas que obligan a medir las rutas para no sucumbir al miasma. Cada moneda suma un timbre agudo que contrarresta el zumbido pantanoso y brilla en el HUD como parte del progreso global.

### Misión final: la Cámara de Resonancia
Cuando el jugador obtiene al menos dos unidades de cada recurso, el Tótem de las Aves en el bioma central vibra y revela—mediante tiles previamente bloqueados—un acceso al norte del mapa: la Cámara de Resonancia. Este santuario funciona como clímax usando únicamente sistemas existentes.

1. **Puerta sonora.** Las compuertas que rodean la cámara se abren automáticamente al cumplirse la cuota. Puede representarse con tiles de roca que el motor reemplace por agua purificada o luz al verificar la meta global.
2. **Pedestales de eco.** Dentro de la cámara hay tres pedestales alineados. Al situarse sobre cada uno, el juego reutiliza la animación y el sonido de recolección para simular la entrega del recurso sin modificar el inventario. Tras completar los tres pasos se dispara la bandera de victoria ya implementada.
3. **Concierto de restauración.** La secuencia final usa el mensaje de victoria actual, pero la narrativa explica que la sinfonía se completó y que las tres ecosferas vuelven a cantar en armonía.

### Recursos y lectura visual
Para facilitar que el jugador identifique el origen de cada reliquia sin leer texto, los sprites de 16x16 píxeles adoptan siluetas claramente distintas:

- **Cristal de magma.** Un pináculo rojizo inclinado hacia el este, con vetas internas amarillas. El degradado va de rojo oscuro en la base (color 4) a brillos incandescentes (E y F) en la cúspide, evocando lava solidificada que aún palpita.
- **Gema glaciar.** Un copo estrellado azul con brazos ortogonales y diagonales. Combina azules profundos (B), medios (D) y destellos blancos (9) alrededor de un núcleo brillante (F), sugiriendo refracciones heladas.
- **Moneda-eco de brea.** Un disco musgoso y aplanado propio de pantano, delineado por borde lodoso (6) y relleno verdoso (A) con vetas ocres (8). Un surco interno en espiral deja ver huecos oscuros para comunicar su cualidad resonante.

### Notas de bitácora en el mundo
- **Formato.** Cada nota es un tile especial (pergamino, tablilla o pluma) colocado sobre el mapa. No ocupa ranuras de inventario.
- **Interacción.** Cuando el jugador se posa sobre el tile, se muestra un cuadro de texto reutilizando la interfaz de diálogos/NPC. Puede detonar un sonido suave y congelar el movimiento mientras se lee.
- **Contenido sugerido.** Tres entradas principales (una por bioma) que narran pistas musicales, más una nota final en la cámara que describe la sinfonía completa.

### Guía para el diseñador de niveles
- **Distribución de recursos.** Ubicar al menos cinco ejemplares de cada reliquia, repartidos en caminos principales y secundarios para motivar la exploración de cada bioma.
- **Ritmo de peligros.** Volcán: alternar plataformas seguras y lava con temporizadores visibles. Nieve: combinar superficies de hielo largas con zonas de frenado. Pantano: mezclar áreas lentas con charcos venenosos que exigen rutas alternativas.
- **Transición al clímax.** Tras abrir la Cámara de Resonancia, colocar decorados neutros (piedra pulida, raíces cristalizadas) para enfatizar que se trata de un espacio fuera de los biomas habituales.

Esta documentación resume la ambientación, la progresión narrativa y las pautas de implementación para que puedas desarrollar el juego completo sin introducir mecánicas nuevas más allá de las ya soportadas por el motor.
