set outfile "ocr.txt"

for file in cropped/*.png
    set pageno (basename $file ".png")

    set IMAGE_PATH $file

    # encode to a file instead of a variable
    base64 -w0 "$IMAGE_PATH" > /tmp/image.b64

    jq -n \
        --rawfile b64 /tmp/image.b64 \
        --arg prompt \
        "Transcribe all text in this image exactly as it appears." \
      '{
        model: "gpt-4-vision-preview",
        messages: [
          {
            role: "user",
            content: [
              {type: "text", text: $prompt},
              {type: "image_url", image_url: {url: ("data:image/png;base64," + $b64)}}
            ]
          }
        ],
        temperature: 0,
        max_tokens: 4096
      }' > payload.json

    echo "" >> $outfile
    echo "["$pageno"]" >> $outfile
    echo "" >> $outfile

    curl -s http://localhost:8080/v1/chat/completions \
        -H "Content-Type: application/json" \
        -d @payload.json | jq -r '.choices[0].message.content' >> $outfile

end
