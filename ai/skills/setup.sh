#!/bin/bash 
mkdir -p ~/.openclaw/skills



cat <<EOF >> ~/.bashrc
init_skill() {
	if [ -z $1 ]; then
		echo "Need skill name"
		return 1
	fi
	python3 /usr/lib/node_modules/openclaw/skills/skill-creator/scripts/init_skill.py ${1} \
		--path ~/skills --resources scripts,references,assets

}

export R2_ENDPOINT=""
export R2_BUCKET="images"
export R2_PUBLIC_BASE=""
export R2_ACCESS_KEY_ID=""
export R2_SECRET_ACCESS_KEY=""
EOF

git clone https://github.com/cloudflare/skills.git ~/.openclaw/skills/cloudflare-skills
