# Usa a imagem oficial já com a UI compilada
FROM gotify/server:v2.6.3

# Define o diretório de trabalho (opcional, mas pode ajudar em personalizações futuras)
WORKDIR /app

# Garante que a pasta de dados exista (ponto de montagem para persistência)
VOLUME ["/app/data"]

# Expõe a porta padrão do Gotify
EXPOSE 80

# O entrypoint padrão da imagem oficial já inicia o servidor corretamente
# ENTRYPOINT ["./gotify-linux-arm64"] (já está definido internamente)
