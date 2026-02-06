package utils;

import java.sql.*; // This replaces all individual sql imports

public class DBConnection {
    private static final String URL = "jdbc:postgresql://localhost:5432/classroom_economy";
    private static final String USER = "postgres";
    private static final String PASS = "Zdcgbjm@2006"; // Use your actual pgAdmin password

    public static Connection getConnection() throws SQLException {
        try {
            Class.forName("org.postgresql.Driver");
            return DriverManager.getConnection(URL, USER, PASS);
        } catch (ClassNotFoundException e) {
            throw new SQLException("JDBC Driver not found!", e);
        }
    }

    public static void main(String[] args) {
        try (Connection conn = getConnection()) {
            if (conn != null) {
                System.out.println("✅ Connection Successful!");
            }
        } catch (SQLException e) {
            System.out.println("❌ Connection Failed!");
            e.printStackTrace();
        }
    }
}