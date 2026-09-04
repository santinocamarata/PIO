-- Sistema PIO — Fichas de excepción
-- Pegar en: https://supabase.com/dashboard/project/ffqpgtordxgtedxixpwi/editor
-- Ejecutar una sola vez.

-- Motivos de excepción
CREATE TABLE IF NOT EXISTS public.motivos (
  id        UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  texto     TEXT        NOT NULL,
  activo    BOOLEAN     NOT NULL DEFAULT true,
  creado_at TIMESTAMPTZ DEFAULT now()
);

-- Fechas de recuperatorio
CREATE TABLE IF NOT EXISTS public.fechas_recuperatorio (
  id        UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  fecha_iso TEXT        NOT NULL,
  activo    BOOLEAN     NOT NULL DEFAULT true,
  creado_at TIMESTAMPTZ DEFAULT now()
);

-- Fichas de excepción
CREATE TABLE IF NOT EXISTS public.fichas (
  id                   UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  folio                TEXT        NOT NULL UNIQUE,
  legajo               TEXT        NOT NULL,
  alumno               TEXT        NOT NULL,
  motivo               TEXT        NOT NULL,
  fecha_recuperatorio  TEXT        NOT NULL,
  adjunto_nombre       TEXT,
  adjunto_tamano       BIGINT,
  adjunto_path         TEXT,
  creada_por           TEXT        NOT NULL,
  creada_at            TIMESTAMPTZ DEFAULT now()
);

-- Padrón de alumnos a ingresar. legajo como clave primaria: ya viene
-- normalizado a 7 dígitos, y permite upsert por legajo al reemplazar el
-- padrón completo desde la aplicación.
CREATE TABLE IF NOT EXISTS public.padron (
  legajo TEXT PRIMARY KEY,
  alumno TEXT NOT NULL
);

-- Metadata del último reemplazo de padrón. Fila única (id fijo en 1): no hace
-- falta una fila por legajo para saber "cuándo se actualizó por última vez".
CREATE TABLE IF NOT EXISTS public.padron_meta (
  id              INT PRIMARY KEY DEFAULT 1,
  origen          TEXT,
  actualizado_por TEXT,
  actualizado_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT padron_meta_singleton CHECK (id = 1)
);

-- Habilitar RLS en las cinco tablas
ALTER TABLE public.motivos              ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.fechas_recuperatorio ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.fichas               ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.padron               ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.padron_meta          ENABLE ROW LEVEL SECURITY;

-- Políticas temporales: acceso anónimo completo.
-- Reemplazar con políticas basadas en Supabase Auth cuando se active el login real.
CREATE POLICY "pio_anon_motivos" ON public.motivos
  FOR ALL TO anon USING (true) WITH CHECK (true);

CREATE POLICY "pio_anon_fechas" ON public.fechas_recuperatorio
  FOR ALL TO anon USING (true) WITH CHECK (true);

CREATE POLICY "pio_anon_fichas" ON public.fichas
  FOR ALL TO anon USING (true) WITH CHECK (true);

CREATE POLICY "pio_anon_padron" ON public.padron
  FOR ALL TO anon USING (true) WITH CHECK (true);

CREATE POLICY "pio_anon_padron_meta" ON public.padron_meta
  FOR ALL TO anon USING (true) WITH CHECK (true);

-- RLS no alcanza sola: sin este GRANT, cada consulta a estas tablas vuelve
-- con 401 "permission denied for table" aunque la política de arriba exista
-- y la clave sea correcta. Costó una sesión entera de diagnóstico entenderlo.
GRANT SELECT, INSERT, UPDATE, DELETE ON public.motivos              TO anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.fechas_recuperatorio TO anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.fichas               TO anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.padron               TO anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.padron_meta          TO anon;

-- Bucket para PDFs (también crear desde Storage > New bucket > "adjuntos", privado)
INSERT INTO storage.buckets (id, name, public)
  VALUES ('adjuntos', 'adjuntos', false)
  ON CONFLICT (id) DO NOTHING;

CREATE POLICY "pio_anon_adjuntos" ON storage.objects
  FOR ALL TO anon
  USING  (bucket_id = 'adjuntos')
  WITH CHECK (bucket_id = 'adjuntos');
