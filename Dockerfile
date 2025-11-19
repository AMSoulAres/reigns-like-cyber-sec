FROM nginx:1.29-alpine

# O Nginx procura arquivos em /usr/share/nginx/html.
COPY build/html/. /usr/share/nginx/html/

# Expõe a porta 80, que é a porta interna que o Nginx está usando
EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]