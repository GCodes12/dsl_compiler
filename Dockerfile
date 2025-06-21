# Use a base image with essential build tools
FROM ubuntu:latest

# Install system dependencies
RUN apt-get update && \
    apt-get install -y flex bison gcc g++ python3 python3-pip nodejs npm && \
    apt-get clean

# Set working directory
WORKDIR /app

# Copy all project files
COPY . .

# ✅ Install Python dependencies (no pip upgrade needed)
RUN pip3 install --break-system-packages -r requirements.txt

# ✅ Install Node.js dependencies
RUN npm install

# ✅ Build the C-based DSL compiler using render-build.sh
RUN bash render-build.sh

# Expose the port your server will run on
EXPOSE 3000

# ✅ Start the Node.js server
CMD ["node", "server.js"]
