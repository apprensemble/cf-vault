# Trucs et astuces

## Comment pointer vers la bonne donnée vcap services

le fichier test.json contient un example de contenu de vcapservice.

VCAP_SERVICES est une variable cloud foundry contenant les objets bindé depuis un service.

Pour vous verifier que vous pointer vers le bon element faire :
```sh
cf env $APP_NAME
# Copier l'objet qui encapsule VCAP_SERVICES et le mettre dans un fichier json(test.json est ce type de fichier)
# Ensuite extraire l'objet VCAP_SERVICES dans une variable d'env. Elle sera identique à celle de la plateforme $APP_NAME
VCAP_SERVICES=$(jq -r '.VCAP_SERVICES' test.json)
# Enfin tester la recuperation d'une propriete(dans notre example hostname)
echo $VCAP_SERVICES | jq -r '.["'$SERVICE'"][0].credentials.hostname'
```

Cette procedure est pratique pour faire des tests sur une plateforme qui ne demarre pas et par conséquent n'offre pas d'accès ssh.
