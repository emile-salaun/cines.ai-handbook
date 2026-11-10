# Prise en main

Découvrir l'environnement GPU d'Adastra. Ce chapitre couvre ce qu'il faut
pour les jobs d'IA ; pour tout le reste, voir la [documentation officielle d'Adastra](https://dci.dci-gitlab.cines.fr/webextranet/).

## Prérequis

- Un identifiant Adastra et un projet avec des heures GPU (`myproject -l`
  liste vos projets).
- Une connexion SSH à un nœud de connexion : `ssh <login>@adastra.cines.fr`.

## Étapes

<div class="cines-steps" markdown>

1. [Adastra en bref](adastra.md) : types de nœuds, espaces de stockage, ce qui
   s'exécute où.
2. [Configurer votre environnement](setup.md) : cloner le dépôt, définir une
   fois votre projet Slurm, choisir l'environnement IA préinstallé ou le vôtre
   (uv), télécharger un modèle de test.
3. [Premier job](first-job.md) : un GPU, vérification de l'environnement.
4. [Modèles de jobs](templates.md) : quel modèle pour quel job, options MI250X.
5. [Session interactive](interactive.md) : travailler sur un nœud de calcul,
   observer un job en cours.
6. [Vérifications GPU et communications](checks.md) : GPU vus par chaque
   processus et RCCL, sur un GPU et un nœud.

</div>

!!! cines "MI300A par défaut"
    Toutes les commandes visent les nœuds MI300A. Pour MI250X, chaque page
    donne la variante dans un second onglet.