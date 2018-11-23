
#!/bin/bash

domains=( "muminfitness.com" "www.muminfitness.com" )
rsa_key_size=4096
data_path="./etc/certbot"
email="mostafa@purealgo.com" #Adding a valid address is strongly recommended 
staging=0 #Set to 1 if you're just testing your setup to avoid hitting request limits

echo "### Preparing directories in $data_path ..."
sudo rm -Rf "$data_path"
sudo mkdir -p "$data_path/www"
sudo mkdir -p "$data_path/conf/live/$domains"


echo "### Creating dummy certificate ..."
path="/etc/letsencrypt/live/$domains"
sudo mkdir -p "$path"
docker-compose run --rm --entrypoint "\
    openssl req -x509 -nodes -newkey rsa:1024 -days 1\
      -keyout '$path/privkey.pem' \
      -out '$path/fullchain.pem' \
      -subj '/CN=localhost'" certbot


echo "### Downloading recommended HTTPS parameters ..."
sudo curl -s https://raw.githubusercontent.com/certbot/certbot/master/certbot-nginx/certbot_nginx/options-ssl-nginx.conf > "$data_path/conf/options-ssl-nginx.conf"
sudo curl -s https://raw.githubusercontent.com/certbot/certbot/master/certbot/ssl-dhparams.pem > "$data_path/conf/ssl-dhparams.pem"


echo "### Starting nginx ..."
docker-compose up -d nginx


echo "### Deleting dummy certificate ..."
sudo rm -Rf "$data_path/conf/live"

echo "### Downloading recommended TLS options ..."
sudo curl -s https://raw.githubusercontent.com/certbot/certbot/master/certbot-nginx/certbot_nginx/options-ssl-nginx.conf > "$data_path/conf/options-ssl-nginx.conf"
sudo curl -s https://raw.githubusercontent.com/certbot/certbot/master/certbot/ssl-dhparams.pem > "$data_path/conf/ssl-dhparams.pem"


echo "### Requesting initial certificate ..."

#Join $domains to -d args
domain_args=""
for domain in "${domains[@]}"; do
  domain_args="$domain_args -d $domain"
done

#Select appropriate email arg
case "$email" in
  "") email_arg="--register-unsafely-without-email" ;;
  *) email_arg="--email $email" ;;
esac

#Enable staging mode if needed
if [ $staging != "0" ]; then staging_arg="--staging"; fi

docker-compose run --rm --entrypoint "\
  certbot certonly --webroot -w /var/www/certbot \
    $staging_arg \
    $email_arg \
    $domain_args \
    --rsa-key-size $rsa_key_size \
    --agree-tos \
    --force-renewal" certbot

docker-compose stop nginx