FROM node:alpine

# Create working directory
WORKDIR /app

# Copy package files to working directory
COPY *.json /app/

# Install the dependencies
RUN npm install

# Copy all the files on working directory 
COPY . /app/

# Expose the app on 3000 port number
EXPOSE 3000

# command to start app
CMD ["npm", "start"]
