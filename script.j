// =====================================================
// CEAI — LOGIQUE PRINCIPALE
// Réécrite à neuf, connexion Supabase intégrée
// =====================================================

// Vos identifiants Supabase
const SUPABASE_URL = "https://sgghvlvwwprhvtsvuveg.supabase.co";
const SUPABASE_CLE = "sb_publishable_w_2_Ndw0ZJAj-bVeXZgIzw_Y09wTTps";

// Initialisation du client Supabase
const supabase = window.supabase.createClient(SUPABASE_URL, SUPABASE_CLE);

// État global
let membreActuel = null;

// ─── Éléments de l'écran d'authentification ───
const authEcran = document.getElementById("authEcran");
const sitePrincipal = document.getElementById("sitePrincipal");
const formConnexion = document.getElementById("formConnexion");
const formInscription = document.getElementById("formInscription");
const authTitre = document.getElementById("authTitre");
const connErreur = document.getElementById("connErreur");
const inscErreur = document.getElementById("inscErreur");
const infosMembre = document.getElementById("infosMembre");

// ─── Basculer Connexion / Inscription ───
document.getElementById("lienVersInscription").addEventListener("click", e => {
  e.preventDefault();
  formConnexion.classList.add("cache");
  formInscription.classList.remove("cache");
  authTitre.textContent = "Inscription";
  effacerErreurs();
});

document.getElementById("lienVersConnexion").addEventListener("click", e => {
  e.preventDefault();
  formInscription.classList.add("cache");
  formConnexion.classList.remove("cache");
  authTitre.textContent = "Connexion";
  effacerErreurs();
});

function effacerErreurs() {
  connErreur.textContent = "";
  inscErreur.textContent = "";
}

// ─── Afficher / Masquer le mot de passe ───
function activerOeil(boutonId, champId) {
  const bouton = document.getElementById(boutonId);
  const champ = document.getElementById(champId);
  bouton.addEventListener("click", () => {
    champ.type = champ.type === "password" ? "text" : "password";
  });
}
activerOeil("btnOeilConn", "connMdp");
activerOeil("btnOeilInsc", "inscMdp");

// ─── Inscription ───
document.getElementById("btnInscription").addEventListener("click", async () => {
  const nom = document.getElementById("inscNom").value.trim();
  const email = document.getElementById("inscEmail").value.trim();
  const mdp = document.getElementById("inscMdp").value;
  inscErreur.textContent = "";
  inscErreur.style.color = "";

  if (!nom || !email || mdp.length < 6) {
    inscErreur.textContent = "Remplissez tous les champs (6 caractères minimum pour le mot de passe)";
    return;
  }

  const { error } = await supabase.auth.signUp({
    email,
    password: mdp,
    options: { data: { nom } }
  });

  if (error) {
    inscErreur.textContent = traduireErreur(error.message);
    return;
  }

  inscErreur.style.color = "#16a34a";
  inscErreur.textContent = "Compte créé ! Bascule vers connexion...";
  setTimeout(() => {
    formInscription.classList.add("cache");
    formConnexion.classList.remove("cache");
    authTitre.textContent = "Connexion";
    effacerErreurs();
  }, 1800);
});

// ─── Connexion ───
document.getElementById("btnConnexion").addEventListener("click", async () => {
  const email = document.getElementById("connEmail").value.trim();
  const mdp = document.getElementById("connMdp").value;
  connErreur.textContent = "";

  const { error } = await supabase.auth.signInWithPassword({ email, password: mdp });
  if (error) connErreur.textContent = traduireErreur(error.message);
});

// ─── Déconnexion ───
document.getElementById("btnDeconnexion").addEventListener("click", async e => {
  e.preventDefault();
  await supabase.auth.signOut();
});

// ─── Charger la fiche membre ───
async function chargerProfil(idCompte) {
  infosMembre.textContent = "Chargement du profil...";

  const { data, error } = await supabase
    .from("membres")
    .select("*")
    .eq("compte_id", idCompte)
    .limit(1);

  if (error) {
    infosMembre.textContent = "Erreur : " + error.message;
    return;
  }

  if (!data || data.length === 0) {
    infosMembre.textContent = "Aucune fiche membre trouvée. Vérifiez le trigger SQL dans Supabase.";
    return;
  }

  membreActuel = data[0];
  infosMembre.textContent = `Bienvenue ${membreActuel.nom} — Rôle : ${membreActuel.role}`;
  mettreAJourAdmin();
}

function mettreAJourAdmin() {
  const estAdmin = membreActuel?.role === "admin";
  document.querySelectorAll(".zone-admin").forEach(el => {
    el.classList.toggle("cache", !estAdmin);
  });
}

// ─── Gestion de la session ───
async function appliquerSession(session) {
  if (session) {
    authEcran.classList.add("cache");
    sitePrincipal.classList.remove("cache");
    await chargerProfil(session.user.id);
  } else {
    authEcran.classList.remove("cache");
    sitePrincipal.classList.add("cache");
    membreActuel = null;
  }
}

// Restaurer session au chargement
supabase.auth.getSession().then(({ data: { session } }) => appliquerSession(session));

// Réagir aux changements de connexion
supabase.auth.onAuthStateChange((_, session) => appliquerSession(session));

// ─── Traduction des messages d'erreur ───
function traduireErreur(message) {
  const correspondances = {
    "Invalid login credentials": "Email ou mot de passe incorrect",
    "User already registered": "Cet email est déjà utilisé",
    "Password should be at least 6 characters": "Le mot de passe doit contenir au moins 6 caractères",
    "Unable to validate email address: invalid format": "Adresse email invalide",
    "Email not confirmed": "Veuillez confirmer votre email avant de vous connecter"
  };
  return correspondances[message.trim()] || `Erreur : ${message}`;
}

// ─── Navigation du menu ───
document.getElementById("btnMenu").addEventListener("click", () => {
  document.getElementById("menuListe").classList.toggle("cache");
});

// Sous-menus dépliants
document.querySelectorAll(".sous-bouton").forEach(bouton => {
  bouton.addEventListener("click", () => {
    const cible = document.getElementById(bouton.dataset.sous);
    cible.classList.toggle("cache");
  });
});

// Navigation entre pages
document.querySelectorAll(".menu-item[data-page]").forEach(lien => {
  lien.addEventListener("click", e => {
    e.preventDefault();
    const pageId = "page-" + lien.dataset.page;
    document.querySelectorAll(".page").forEach(p => p.classList.remove("active"));
    document.getElementById(pageId)?.classList.add("active");
    document.getElementById("menuListe").classList.add("cache");
  });
});
