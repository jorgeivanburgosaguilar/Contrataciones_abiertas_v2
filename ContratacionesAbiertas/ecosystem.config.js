module.exports = {
    apps: [
        {
            name: 'GDMX',
            script: './captura/gdmx.js',
            cron_restart: '*/15 * * * *', // repetir cada 15 minutos
            env: {
                // conexion a postgres
                POSTGRES_HOST: '',
                POSTGRES_PORT: '',
                POSTGRES_NAME: '',
                POSTGRES_USER: '',
                POSTGRES_PASSWORD: '',
                // conexion del ftp
                FTP_HOST: 'ip del ftp',
                FTP_USER: 'usuario',
                FTP_PASSWORD: 'contraseña',
                FTP_DIRECTORY: 'raiz del directorio desde donde se leen los archivos',
                DOC_URL: 'url a contrataciones'
            }
        }
    ]
};
