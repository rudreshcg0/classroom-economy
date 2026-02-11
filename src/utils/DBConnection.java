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
            if (input == null) {
                System.out.println("⚠️ Sorry, unable to find db.properties");
            } else {
                prop.load(input);
                url = prop.getProperty("db.url");
                user = prop.getProperty("db.user");
                pass = prop.getProperty("db.pass");
            }
        } catch (Exception ex) {
            ex.printStackTrace();
        }
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