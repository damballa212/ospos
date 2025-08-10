services:
  ospos:
    build:
      context: .
      dockerfile: Dockerfile
    restart: unless-stopped
    environment:
      - MYSQL_HOST=db
      - MYSQL_DATABASE=ospos
      - MYSQL_USER=ospos
      - MYSQL_PASSWORD=marlon212
      - ENCRYPTION_KEY=V4rK8pQ2tN6yM1zR5xC7bL9dF3hJ7sK2
      - TZ=America/Caracas
    depends_on:
      - db
    expose:
      - "80"
    volumes:
      - ospos_uploads:/var/www/html/public/uploads
      - ospos_logs:/var/www/html/application/logs

  db:
    image: mariadb:10.6
    restart: unless-stopped
    environment:
      - MYSQL_ROOT_PASSWORD=marlon212
      - MYSQL_DATABASE=ospos
      - MYSQL_USER=ospos
      - MYSQL_PASSWORD=marlon212
    healthcheck:
      test: ["CMD-SHELL", "mysqladmin ping -h 127.0.0.1 -uroot -p$$MYSQL_ROOT_PASSWORD || exit 1"]
      interval: 30s
      timeout: 5s
      retries: 10
    volumes:
      - ospos_db:/var/lib/mysql

volumes:
  ospos_db:
  ospos_uploads:
  ospos_logs:
