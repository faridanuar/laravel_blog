FROM php:8.1-fpm

# Arguments defined in docker-compose.yml
ARG user
ARG uid
ARG dbuser
ARG dbpass
ARG dbname

# Set non-interactive environment
ENV DEBIAN_FRONTEND noninteractive

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
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install PHP extensions
RUN docker-php-ext-install pdo_mysql mbstring exif pcntl bcmath gd

# Get latest Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Create system user to run Composer and Artisan Commands
RUN useradd -G www-data,root -u $uid -d /home/$user $user
RUN mkdir -p /home/$user/.composer && \
    chown -R $user:$user /home/$user

# Set working directory
WORKDIR /var/www

# Run composer install
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Switch to the user for running Composer and Artisan Commands
USER $user

# Copy the Laravel project files into the image
COPY . /var/www

# Install dependencies and generate the optimized autoload files
RUN composer install --no-interaction --optimize-autoloader

# Install MariaDB
USER root
RUN service mariadb start && \
    mysql -e "CREATE DATABASE IF NOT EXISTS $dbname;" && \
    mysql -e "CREATE USER '$dbuser'@'localhost' IDENTIFIED BY '$dbpass';" && \
    mysql -e "GRANT ALL PRIVILEGES ON $dbname.* TO '$dbuser'@'localhost';" && \
    mysql -e "FLUSH PRIVILEGES;"

# Run artisan migrate and seed
RUN php artisan migrate --force
RUN php artisan db:seed --force

# Install Nginx
USER root
RUN apt-get install -y nginx
COPY ./docker-compose/nginx/blog.conf /etc/nginx/sites-available/default
RUN ln -s /etc/nginx/sites-available/default /etc/nginx/sites-enabled

# Expose ports
EXPOSE 80

# Start Nginx and PHP-FPM
CMD service php8.1-fpm start && nginx -g "daemon off;"
