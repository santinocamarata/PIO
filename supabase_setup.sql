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

-- Habilitar RLS en las tres tablas
ALTER TABLE public.motivos              ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.fechas_recuperatorio ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.fichas               ENABLE ROW LEVEL SECURITY;

-- Políticas temporales: acceso anónimo completo.
-- Reemplazar con políticas basadas en Supabase Auth cuando se active el login real.
CREATE POLICY "pio_anon_motivos" ON public.motivos
  FOR ALL TO anon USING (true) WITH CHECK (true);

CREATE POLICY "pio_anon_fechas" ON public.fechas_recuperatorio
  FOR ALL TO anon USING (true) WITH CHECK (true);

CREATE POLICY "pio_anon_fichas" ON public.fichas
  FOR ALL TO anon USING (true) WITH CHECK (true);

-- Bucket para PDFs (también crear desde Storage > New bucket > "adjuntos", privado)
INSERT INTO storage.buckets (id, name, public)
  VALUES ('adjuntos', 'adjuntos', false)
  ON CONFLICT (id) DO NOTHING;

CREATE POLICY "pio_anon_adjuntos" ON storage.objects
  FOR ALL TO anon
  USING  (bucket_id = 'adjuntos')
  WITH CHECK (bucket_id = 'adjuntos');
