FROM svfe/svfe-api-firmador:v20230109

COPY entrypoint.sh /entrypoint.sh

EXPOSE 8113

ENTRYPOINT ["sh", "/entrypoint.sh"]
