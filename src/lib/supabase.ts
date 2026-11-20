import { createClient } from "@supabase/supabase-js";

const supabaseUrl = import.meta.env.VITE_SUPABASE_URL?.trim();
const supabaseAnonKey = import.meta.env.VITE_SUPABASE_ANON_KEY?.trim();
const hasPlaceholder = (value: string) => /YOUR_|REPLACE_ME|<.*>/.test(value);

function isValidSupabaseUrl(value: string | undefined): value is string {
  if (!value || hasPlaceholder(value)) return false;
  try {
    const url = new URL(value);
    return (url.protocol === "https:" || url.hostname === "localhost") && Boolean(url.host);
  } catch {
    return false;
  }
}

export const isSupabaseConfigured =
  isValidSupabaseUrl(supabaseUrl) &&
  Boolean(supabaseAnonKey && !hasPlaceholder(supabaseAnonKey));

// Only the public/publishable anon key belongs in the browser.
// Protect all user data with Supabase Row Level Security (RLS).
export const supabase = isSupabaseConfigured
  ? createClient(supabaseUrl, supabaseAnonKey!)
  : null;

export async function checkSupabaseConnection(): Promise<{ ok: boolean; message: string }> {
  if (!supabase) {
    return {
      ok: false,
      message: "Configura VITE_SUPABASE_URL e VITE_SUPABASE_ANON_KEY com os valores do teu projeto.",
    };
  }

  try {
    // A successful request confirms network access, API key validity, and that the schema exists.
    // RLS may return zero rows while signed out; that still means the connection works.
    const { error } = await supabase
      .from("projects")
      .select("id", { head: true, count: "exact" })
      .limit(1);

    if (error) {
      return {
        ok: false,
        message: `A API respondeu, mas a tabela projects não está acessível: ${error.message}. Executa supabase/schema.sql no SQL Editor.`,
      };
    }

    return { ok: true, message: "Ligação ao Supabase confirmada e tabela projects acessível." };
  } catch (error) {
    const detail = error instanceof Error ? error.message : "erro desconhecido";
    return { ok: false, message: `Não foi possível contactar o Supabase: ${detail}` };
  }
}
