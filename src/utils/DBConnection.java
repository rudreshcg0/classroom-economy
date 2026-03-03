package utils;

import com.zaxxer.hikari.HikariConfig;
import com.zaxxer.hikari.HikariDataSource;
import java.sql.Connection;
import java.sql.SQLException;
import java.util.Properties;
import java.io.InputStream;

public class DBConnection {
    private static HikariDataSource dataSource;

    static {
        try {
            HikariConfig config = new HikariConfig();
            config.setDriverClassName("org.postgresql.Driver");

            // 1. Try to get credentials from Railway Environment Variables first
            String dbUrl = System.getenv("DATABASE_URL"); // Railway provides this full URL
            
            if (dbUrl != null) {
                // PRODUCTION MODE (Railway)
                config.setJdbcUrl(dbUrl);
            } else {
                // LOCAL DEVELOPMENT MODE (db.properties)
                try (InputStream input = DBConnection.class.getClassLoader().getResourceAsStream("utils/db.properties")) {
                    Properties prop = new Properties();
                    if (input == null) throw new RuntimeException("db.properties not found");
                    prop.load(input);
                    
                    config.setJdbcUrl(prop.getProperty("db.url"));
                    config.setUsername(prop.getProperty("db.user"));
                    config.setPassword(prop.getProperty("db.pass"));
                }
            }

            // 2. Performance Hardening for Production
            config.setMaximumPoolSize(10);
            config.setMinimumIdle(2);
            config.setConnectionTimeout(30000); // 30 seconds
            config.setIdleTimeout(600000); // 10 minutes
            config.setMaxLifetime(1800000); // 30 minutes

            dataSource = new HikariDataSource(config);

        } catch (Exception ex) {
            ex.printStackTrace();
            throw new RuntimeException("Database Pool Initialization Failed!", ex);
        }
    }

    public static Connection getConnection() throws SQLException {
        return dataSource.getConnection();
    }
}