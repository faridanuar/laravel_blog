FROM php:8.1-fpm

USER root

# Arguments defined in docker-compose.yml
ARG USER
ARG UID
ARG DBUSER
ARG DBPASS
ARG DBNAME

# Set non-interactive environment
ENV DEBIAN_FRONTEND noninteractive

# Expose ports
EXPOSE 9000 80

# Set working directory
WORKDIR /var/www/html

# Create log dir
# RUN mkdir /var/www/log
# RUN mkdir /var/www/log/nginx
# RUN echo "" > /var/www/log/nginx/error.log
# RUN echo "" > /var/www/log/nginx/access.log

# Copy the Laravel project files into the image
COPY . /var/www/html/

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git \
    curl \
    libpng-dev \
    libonig-dev \
    libxml2-dev \
    zip \
    unzip \
    mariadb-server \
    nginx \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install PHP extensions
RUN docker-php-ext-install pdo_mysql mbstring exif pcntl bcmath gd

# Get latest Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Create system user to run Composer and Artisan Commands
RUN useradd -G www-data,root -u $UID -d /home/$USER $USER
RUN mkdir -p /home/$USER/.composer && \
    chown -R $USER:$USER /home/$USER

# Install MariaDB
RUN service mariadb start && \
    mysql -e "CREATE DATABASE IF NOT EXISTS $DBNAME;" && \
    mysql -e "CREATE USER '$DBUSER'@'localhost' IDENTIFIED BY '$DBPASS';" && \
    mysql -e "GRANT ALL PRIVILEGES ON $DBNAME.* TO '$DBUSER'@'localhost';" && \
    mysql -e "FLUSH PRIVILEGES;"

# Remove existing symbolic link if it exists
RUN rm -f /etc/nginx/sites-enabled/default

# Overwrite default conf with new file
COPY ./docker-compose/nginx/nginx.conf /etc/nginx/sites-available/default

# Create nginx symbolic link
RUN ln -s /etc/nginx/sites-available/default /etc/nginx/sites-enabled

# Run composer install
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer
ENV COMPOSER_ALLOW_SUPERUSER 1

# Create .env file (for flo server deployment)
RUN echo "\
    APP_NAME='blog'\n\
    APP_ENV='dev'\n\
    APP_KEY='base64:kfznkW1ss6s5c8hCQsYyO/vCjHeFaDSTCqosqIh7dz4='\n\
    APP_DEBUG=true\n\
    APP_URL=localhost\n\
    LOG_CHANNEL=stack\n\
    LOG_LEVEL=debug\n\
    DB_CONNECTION=mysql\n\
    DB_HOST=127.0.0.1\n\
    DB_PORT=3306\n\
    DB_DATABASE=blog\n\
    DB_USERNAME=farid\n\
    DB_PASSWORD=secret\n\
    BROADCAST_DRIVER=log\n\
    CACHE_DRIVER=file\n\
    QUEUE_CONNECTION=sync\n\
    SESSION_DRIVER=file\n\
    SESSION_LIFETIME=120\n\
    MEMCACHED_HOST=127.0.0.1\n\
    REDIS_HOST=127.0.0.1\n\
    REDIS_PASSWORD=null\n\
    REDIS_PORT=6379\n\
    MAIL_MAILER=smtp\n\
    MAIL_HOST=mailhog\n\
    MAIL_PORT=1025\n\
    MAIL_USERNAME=null\n\
    MAIL_PASSWORD=null\n\
    MAIL_ENCRYPTION=null\n\
    MAIL_FROM_ADDRESS=null\n\
    MAIL_FROM_NAME='${APP_NAME}'\n\
    AWS_ACCESS_KEY_ID=\n\
    AWS_SECRET_ACCESS_KEY=\n\
    AWS_DEFAULT_REGION=us-east-1\n\
    AWS_BUCKET=\n\
    PUSHER_APP_ID=\n\
    PUSHER_APP_KEY=\n\
    PUSHER_APP_SECRET=\n\
    PUSHER_APP_CLUSTER=mt1\n\
    MIX_PUSHER_APP_KEY='${PUSHER_APP_KEY}'\n\
    MIX_PUSHER_APP_CLUSTER='${PUSHER_APP_CLUSTER}'\n\
    MAILCHIMP_KEY=\n\
    MAILCHIMP_LIST_SUBSCRIBERS=\n\
    " > /var/www/html/.env

# Debug output section when running dockerfile
# RUN chown -R $USER:$USER /var/www/html/
# RUN composer --version
# RUN ls -al /var/www/html/
RUN composer clear-cache

# Install dependencies and generate the optimized autoload files
RUN composer install --optimize-autoloader

# Run artisan migrate and seed
RUN php /var/www/html/artisan migrate --force
RUN php /var/www/html/artisan db:seed --force

# Create Laravel storage symbolic link
RUN php artisan storage:link

# Change files to correct permission
RUN chown -R www-data:www-data /var/www/html
RUN chown -R www-data:www-data /var/www/html/storage

# Start Nginx and PHP-FPM
CMD nginx -g "daemon off;"
