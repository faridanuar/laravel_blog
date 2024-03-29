# Laravel From Scratch Blog Demo Project

http://laravelfromscratch.com

## Installation

First clone this repository, install the dependencies, and setup your .env file.

```
git clone git@github.com:JeffreyWay/Laravel-From-Scratch-Blog-Project.git blog
composer install
cp .env.example .env
```

Then create the necessary database.

```
php artisan db
create database blog
```

And run the initial migrations and seeders.

```
php artisan migrate --seed
```

run this command to create storage symlink so the files are accessible to the public

```
php artisan storage:link

```

if you run in wamp make these symbolic links

```
mklink /d C:\projects\laravel\blog\public\js C:\projects\laravel\blog\resources\js

```

## Further Ideas

Of course we only had time in the Laravel From Scratch series to review the essentials of a blogging platform. You can certainly take this many
steps further. Here are some quick ideas that you might play with.

3. Add an RSS feed that lists all posts in chronological order.
4. Record/Track and display the "views_count" for each post.
5. Allow registered users to "follow" certain authors. When they publish a new post, an email should be delivered to all followers.
6. Allow registered users to "bookmark" certain posts that they enjoyed. Then display their bookmarks in a corresponding settings page.
