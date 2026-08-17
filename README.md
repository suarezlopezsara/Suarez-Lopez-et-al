# Suarez-Lopez-et-al
FIji Macros used for image analysis 
# Macros de Fiji para [nombre del paper]

Este repositorio contiene las macros de Fiji/ImageJ usadas para el análisis 
de imágenes del paper "[título]" (Cell Reports, [año]).

## Requisitos
- Fiji (ImageJ) versión [la que uses]
- Plugins necesarios: [si usaste alguno, ej. StarDist]

## Macros incluidas

### 1. segmentacion_celulas.ijm
Segmenta células individuales en las imágenes a partir de [canal/marcador].
- Input: imágenes .tif originales
- Output: ROIs/máscaras de segmentación por célula

### 2. medicion_GluA1_intensity.ijm
Mide la intensidad de GluA1 dentro de las células segmentadas en el paso anterior.
- Input: ROIs generadas por segmentacion_celulas.ijm + imagen original
- Output: tabla con valores de intensidad por célula

### 3. medicion_GluA1_en_shank2.ijm
Mide la intensidad de GluA1 específicamente en las áreas positivas para Shank2.
- Input: ROIs de segmentación + canal de Shank2 + canal de GluA1
- Output: tabla con valores de intensidad de GluA1 restringidos a áreas Shank2

## Orden de uso
1. Ejecutar `segmentacion_celulas.ijm` sobre las imágenes originales
2. Ejecutar `medicion_GluA1_intensity.ijm` usando las ROIs generadas
3. Ejecutar `medicion_GluA1_en_shank2.ijm` para el análisis específico en áreas Shank2
