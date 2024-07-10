# Actualizar los paquetes
sudo yum update -y

# Instalar MySQL
sudo yum install -y mariadb-server

# Iniciar el servicio de MySQL
sudo systemctl start mariadb

# Habilitar MySQL para que inicie al arrancar
sudo systemctl enable mariadb

# Configurar la instalación de MySQL
sudo mysql_secure_installation

# Crear usuario y base de datos
sudo mysql -u root -p

sudo mysql -u omni_user -p

CREATE DATABASE omni_test;
CREATE USER 'omni_user'@'%' IDENTIFIED BY 'OmniPass$123';
GRANT SELECT, INSERT, UPDATE, DELETE ON omni_test.* TO 'omni_user'@'%';
FLUSH PRIVILEGES;

SHOW GRANTS FOR 'omni_user'@'%';

SHOW DATABASES;

USE omni_test;
CREATE TABLE usuarios (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(500) NOT NULL
);

DESCRIBE usuarios;


