workflow "Publish SSG" {
  on = "push"
  resolves = ["GitHub Action for Firebase"]
}

action "GitHub Action for Firebase" {
  needs = "action hugo"
  uses = "w9jds/firebase-action@7d6b2b058813e1224cdd4db255b2f163ae4084d3"
  secrets = ["FIREBASE_TOKEN"]
  env = {
    PROJECT_ID = "seedshare"
  }
}

action "action hugo" {
  uses = "./action-hugo"
}
