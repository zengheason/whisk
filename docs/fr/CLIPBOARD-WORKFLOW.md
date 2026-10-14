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

Glissez une carte sur un groupe pour l’y ajouter. Répéter le dépôt ne la
retire pas du groupe. Le panneau reste visible pendant les dépôts internes.
Le glisser vers une autre application reste possible hors du panneau.

Les nouveaux groupes alternent entre six couleurs, visibles sur leur bouton
et l’en-tête des cartes. Le groupe actif est prioritaire ; sinon, la première
appartenance fournit la couleur. Clic droit → **Couleur du groupe** permet de
la modifier. Les groupes existants deviennent bleus. Cliquez sur un groupe,
puis appuyez sur Retour pour le renommer ; Retour valide, Échap annule.
Les filtres de groupe utilisent les mêmes cartes que les autres filtres.
Les raccourcis Commande réservent leur place même lorsqu’ils sont masqués.

La création et le renommage modifient directement le bouton du groupe ;
les cartes restent visibles. Retour valide, Échap annule. Un nom invalide
conserve le champ avec un contour rouge et une infobulle explicative.
Les cartes gardent leur verre dépoli ; seul un petit point indique le groupe.
Les marges du titre et du contenu sont identiques pour toutes les cartes.
Les dépôts internes gardent le panneau ouvert malgré les changements de focus.

Les changements de focus ne ferment plus le panneau. Seuls un nouveau clic
extérieur, Échap ou une activation explicite le ferment. La fin d’un glisser
ne devient pas un clic sur la carte. Aucune temporisation ne ferme le panneau.

Le filtre de groupe est à sélection unique : choisir un groupe remplace le
précédent ; le choisir à nouveau annule le filtre. Les appartenances multiples
restent possibles. Le texte et le code des cartes utilisent une police de 14 points.

Lorsque le panneau est ouvert, une couche transparente intercepte les gestes
sur les écrans connectés. Le défilement extérieur est dirigé vers les cartes ;
les balayages de navigation ne passent plus aux applications en dessous. Un
clic extérieur ferme le panneau et retire la couche, indépendamment du verre.

Le panneau utilise ⇧⌘V et la pile ⌃⌥⌘V par défaut, laissant ⌘⌥V à Finder.
Tous les raccourcis restent personnalisables, y compris ⇧⌘V. Les réglages
existants sont conservés. Un conflit potentiel affiche un avertissement après
l’enregistrement, sans bloquer le choix. Les champs de texte conservent copier,
couper, coller, tout sélectionner et annuler.

Finder reste responsable du déplacement : ⌘C, dossier cible, puis ⌘⌥V.
Whisk conserve les références des fichiers sans les copier puis les supprimer.
Les droits, conflits, annulations et transferts entre volumes restent gérés par
Finder. Les anciennes références ne sont pas des sauvegardes de fichiers déplacés.


Le panneau et la couche extérieure partagent une seule route de défilement.
La zone initiale conserve le geste et son inertie même lorsque le pointeur
traverse les espaces entre cartes ou les filtres. Les points extérieurs sont
dirigés vers les cartes ; chaque événement n’est transmis qu’une fois. Le
survol ne change plus la sélection pendant le défilement. Les cartes s’alignent
à l’arrêt sans limiter le déplacement à une carte. Le montage des cartes
visibles avance par groupes de quatre pour réduire les mises à jour.


Le transport du presse-papiers universel dépend de Handoff dans macOS.
Lorsque les données attendues ne sont pas encore disponibles, Whisk réessaie
la même génération jusqu’à 40 fois. La capture réussie et les écritures de
Whisk restent consommées une seule fois. Les données confidentielles ou les
types inconnus seuls sont ignorés. La pause abandonne les changements en
attente pour éviter une capture différée après reprise. Le marqueur distant
n’exclut pas le contenu. Les tests privés simulent l’arrivée différée ; le
transfert réel depuis un iPhone dépend toujours de la connexion système.
