-- Chat policies (simple y consistente con este proyecto)
-- Ejecuta este script en Supabase SQL Editor.

begin;

-- 1) Activar RLS en mensajes
alter table if exists public.mensajes enable row level security;

-- 2) Limpiar policies previas de chat (si existían)
drop policy if exists mensajes_select_miembro_grupo on public.mensajes;
drop policy if exists mensajes_insert_miembro_grupo on public.mensajes;

-- 3) Crear policies según columnas existentes en mensajes
-- Soporta ambos esquemas:
--   A) id_grupo + id_usuario
--   B) grupo_id + usuario_id

do $$
declare
  tiene_id_grupo boolean;
  tiene_id_usuario boolean;
  tiene_grupo_id boolean;
  tiene_usuario_id boolean;
begin
  select exists (
    select 1 from information_schema.columns
    where table_schema = 'public' and table_name = 'mensajes' and column_name = 'id_grupo'
  ) into tiene_id_grupo;

  select exists (
    select 1 from information_schema.columns
    where table_schema = 'public' and table_name = 'mensajes' and column_name = 'id_usuario'
  ) into tiene_id_usuario;

  select exists (
    select 1 from information_schema.columns
    where table_schema = 'public' and table_name = 'mensajes' and column_name = 'grupo_id'
  ) into tiene_grupo_id;

  select exists (
    select 1 from information_schema.columns
    where table_schema = 'public' and table_name = 'mensajes' and column_name = 'usuario_id'
  ) into tiene_usuario_id;

  if tiene_id_grupo and tiene_id_usuario then
    execute $sql$
      create policy mensajes_select_miembro_grupo
      on public.mensajes
      for select
      to authenticated
      using (
        exists (
          select 1
          from public.miembros m
          where m.id_grupo = mensajes.id_grupo
            and m.id_usuario = auth.uid()
        )
      )
    $sql$;

    execute $sql$
      create policy mensajes_insert_miembro_grupo
      on public.mensajes
      for insert
      to authenticated
      with check (
        id_usuario = auth.uid()
        and exists (
          select 1
          from public.miembros m
          where m.id_grupo = mensajes.id_grupo
            and m.id_usuario = auth.uid()
        )
      )
    $sql$;

  elsif tiene_grupo_id and tiene_usuario_id then
    execute $sql$
      create policy mensajes_select_miembro_grupo
      on public.mensajes
      for select
      to authenticated
      using (
        exists (
          select 1
          from public.miembros m
          where m.id_grupo = mensajes.grupo_id
            and m.id_usuario = auth.uid()
        )
      )
    $sql$;

    execute $sql$
      create policy mensajes_insert_miembro_grupo
      on public.mensajes
      for insert
      to authenticated
      with check (
        usuario_id = auth.uid()
        and exists (
          select 1
          from public.miembros m
          where m.id_grupo = mensajes.grupo_id
            and m.id_usuario = auth.uid()
        )
      )
    $sql$;

  else
    raise exception 'No se reconocieron columnas de grupo/usuario en public.mensajes';
  end if;
end $$;

commit;
