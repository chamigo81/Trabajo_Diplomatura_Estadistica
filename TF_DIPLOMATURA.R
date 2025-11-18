###[*BLOQUE 0: configuración inicial ----

install.packages("readxl")     # para leer Excel
install.packages("readtext")   # para leer Word y PDF
install.packages("stringr")    # para extraer número de solicitud del texto
library(readxl)
library(readtext)
library(stringr)

setwd("C:/padyf")
df <- read_excel("ds_mineria.xlsx", sheet = 1)

# --- 2. leer todos los word ----
carpeta_informes <- "C:/padyf/informes"

docs <- readtext(
  file.path(carpeta_informes, "**/*.docx"),
  ignore_missing_files = TRUE
)

# --- 3. extraer el número de solicitud DESDE EL NOMBRE DEL ARCHIVO ----
docs$solicitud <- as.numeric(str_extract(docs$doc_id, "\\d+"))

# --- 4. unir Excel + Word ----
df_final <- merge(df, docs,
                  by.x = "nsolicitud",
                  by.y = "solicitud",
                  all.x = TRUE)

View(df_final)

table(is.na(df_final$text))
sin_informe <- df_final[is.na(df_final$text), "nsolicitud"]
sin_informe

# --- Visualizamos las observaciones correctas
df_final$informe_existe <- ifelse(df_final$nsolicitud %in% docs$solicitud, 1, 0)
# --- Visualizamos las observaciones que no se pudieron hacer un match entre el campo
# --- del .xlsx y los archivos word (nro. de solicitud)
df_final[df_final$informe_existe == 0, c("nsolicitud", "agente")]


##############
# ----- BLOQUE 1: limpieza de texto -----

install.packages("tm")
install.packages("janitor")
library(tm)
library(janitor)

# hacemos copia
df_clean <- df_final

# convertir NA a vacío
df_clean$text[is.na(df_clean$text)] <- ""

# crear corpus
corpus <- VCorpus(VectorSource(df_clean$text))

# funciones de limpieza
corpus <- tm_map(corpus, content_transformer(tolower))
corpus <- tm_map(corpus, content_transformer(janitor::remove_accents))
corpus <- tm_map(corpus, removeNumbers)
corpus <- tm_map(corpus, removePunctuation)
corpus <- tm_map(corpus, stripWhitespace)

# stopwords en español
corpus <- tm_map(corpus, removeWords, stopwords("spanish"))

# guardar texto limpio en el dataframe
df_clean$text_clean <- sapply(corpus, as.character)

View(df_clean)


