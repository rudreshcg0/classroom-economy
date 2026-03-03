package utils;

import java.sql.*;
import org.mindrot.jbcrypt.BCrypt;

public class HashExistingPasswords {
    public static void main(String[] args) {
        System.out.println("Starting password migration...");
        
        try (Connection conn = DBConnection.getConnection()) {
            // 1. Fetch all users with plain-text passwords
            String selectSql = "SELECT user_id, password FROM users";
            Statement stmt = conn.createStatement(ResultSet.TYPE_SCROLL_SENSITIVE, ResultSet.CONCUR_UPDATABLE);
            ResultSet rs = stmt.executeQuery(selectSql);

            int count = 0;
            while (rs.next()) {
                int id = rs.getInt("user_id");
                String plainText = rs.getString("password");

                // 2. Skip if already hashed (BCrypt hashes start with $2a$ or $2b$)
                if (plainText.startsWith("$2a$")) {
                    continue;
                }

                // 3. Hash and Update
                String hashed = BCrypt.hashpw(plainText, BCrypt.gensalt());
                
                try (PreparedStatement updatePst = conn.prepareStatement(
                        "UPDATE users SET password = ? WHERE user_id = ?")) {
                    updatePst.setString(1, hashed);
                    updatePst.setInt(2, id);
                    updatePst.executeUpdate();
                }
                count++;
            }
            System.out.println("Migration successful! Hashed " + count + " passwords.");
            
        } catch (SQLException e) {
            e.printStackTrace();
        }
    }
}