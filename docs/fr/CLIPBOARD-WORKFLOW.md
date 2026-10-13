# Utilisation du presse-papiers

Maintenez Commande dans le panneau pour afficher ⌘1 à ⌘9 sur les neuf
premières cartes, dans l’ordre du filtre courant. Relâcher Commande masque
les numéros. Les raccourcis suivent exactement cet ordre.

Sélectionner une carte la copie dans le presse-papiers et ferme le panneau.
Appuyez sur ⌘V pour la coller. Le réglage **Coller automatiquement après
sélection**, désactivé par défaut, permet de réactiver le collage direct.
Le texte brut et les transformations retirent volontairement le formatage.
La sélection normale et la pile restaurent les représentations originales.

Le bouton **Nouveau groupe…**, après les catégories, crée un groupe.
Un clic droit sur une carte → **Groupes** permet de modifier ses appartenances.
Une carte peut appartenir à plusieurs groupes. Leurs filtres se combinent
avec la source, la catégorie et la recherche. Un clic droit sur un groupe
permet de le renommer ou de le supprimer. Les cartes classées sont protégées
contre l’effacement global, l’expiration et les limites de capacité.
Retirer le dernier groupe rend une carte non épinglée à nouveau soumise à
la politique de conservation.

Le réglage **Effet de verre dépoli** contrôle les cartes, la recherche, les
filtres, l’éditeur, l’aperçu et le flou de fond séparé. Désactivé, il utilise
des surfaces opaques. L’option macOS Réduire la transparence reste prioritaire.

Les nouvelles captures conservent localement les représentations HTML, RTF,
propres aux applications et les limites entre éléments. La copie normale
restaure leurs octets sans conversion. Des textes identiques de formats
différents restent distincts. L’application destinataire choisit le format
qu’elle prend en charge. Les formats perdus dans les anciennes versions
nécessitent une nouvelle copie depuis leur source.

Les groupes sont enregistrés dans `groups.json` à côté de `history.sqlite`.
Les appartenances et les formats originaux utilisent de nouvelles tables
SQLite ; les anciennes entrées restent lisibles. Sauvegardez le répertoire
de données complet.
