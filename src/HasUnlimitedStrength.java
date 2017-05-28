import javax.crypto.Cipher;

class HasUnlimitedStrength {
    public static void main(String[] args) throws Exception {
        int maxKeyLen = Cipher.getMaxAllowedKeyLength("AES");
        System.out.println(maxKeyLen == Integer.MAX_VALUE ? "YES" : "NO");
    }
}