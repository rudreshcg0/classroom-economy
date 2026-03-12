package utils;

import java.sql.*;
import java.util.Properties;
import java.io.InputStream;

public class DBConnection {
    private static String url;
    private static String user;
    private static String pass;

    // Static block runs once when the class is loaded to read the file
    static {
    try (InputStream input = DBConnection.class.getClassLoader().getResourceAsStream("utils/db.properties")) {
        Properties prop = new Properties();
        if (input != null) prop.load(input);

        // Check Environment Variables first (Standard Linux practice), fallback to file
        url = System.getenv("DB_URL") != null ? System.getenv("DB_URL") : prop.getProperty("db.url");
        user = System.getenv("DB_USER") != null ? System.getenv("DB_USER") : prop.getProperty("db.user");
        pass = System.getenv("DB_PASS") != null ? System.getenv("DB_PASS") : prop.getProperty("db.pass");
    } catch (Exception ex) { ex.printStackTrace(); }
}

    public static Connection getConnection() throws SQLException {
        try {
            Class.forName("org.postgresql.Driver");
            return DriverManager.getConnection(url, user, pass);
        } catch (ClassNotFoundException e) {
            throw new SQLException("JDBC Driver not found!", e);
        }
    }
}
