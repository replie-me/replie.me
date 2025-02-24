import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  output: 'standalone',
  experimental: {
    serverActions: {
      allowedOrigins: ["localhost:3000"],
    },
  },
  server: {
    https: process.env.NODE_ENV !== 'production' ? {
      key: process.env.HTTPS_KEY_PATH,
      cert: process.env.HTTPS_CERT_PATH,
    } : undefined,
  },
  images: {
    remotePatterns: [
      {
        protocol: "https",
        hostname: "lh3.googleusercontent.com",
        port: "",
        pathname: "/a/**",
        search: "",
      },
    ],
  },
};

export default nextConfig;
