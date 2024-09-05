unit Unit1;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,
  mormot.crypt.secure, mormot.crypt.core, System.NetEncoding;

type
  TForm1 = class(TForm)
    Button1: TButton;
    Button2: TButton;
    Label1: TLabel;
    Edit1: TEdit;
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
  private
    procedure AESGCMENCRYPT;
    procedure AESGCMDECRYPT;
  public
    AES: TAesGcmEngine;
    Key: array[0..31] of Byte;       // 256-bit key (32 bytes)
    Nonce: array[0..11] of Byte;     // 96-bit nonce (12 bytes)
    PlainText, CipherText: TBytes;
    Tag: TAesBlock;                  // Tag for authentication (16 bytes)
    DecryptedText: TBytes;
    Success: Boolean;
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}

procedure TForm1.Button1Click(Sender: TObject);
begin
  AESGCMENCRYPT; // Encrypt procedure
  //disable the encrypt button...
   self.Button2.Enabled:=True;
  self.Button1.Enabled:=False;
end;

procedure TForm1.Button2Click(Sender: TObject);
begin
  AESGCMDECRYPT; // Decrypt procedure
  self.Button2.Enabled:=false;
  self.Button1.Enabled:=true;
end;

procedure TForm1.AESGCMENCRYPT;
begin
  try
    // Define the plaintext message
    PlainText := TEncoding.UTF8.GetBytes(Edit1.Text);

    // Generate a random AES-GCM key (256-bit key)
    TAesPrng.Main.Fill(@Key, SizeOf(Key)); // Securely generate a random key

    // Generate a random nonce (12 bytes is standard for AES-GCM)
    TAesPrng.Main.Fill(@Nonce, SizeOf(Nonce));

    // Initialize the AES-GCM object with the key
    AES.Init(Key, 256);   // Initialize with the 256-bit key
    try
      // Set nonce for encryption
      AES.Reset(@Nonce, SizeOf(Nonce));

      // Allocate space for the ciphertext
      SetLength(CipherText, Length(PlainText) + 16); // +16 bytes for potential tag

      // Encrypt the plaintext
      Success := AES.Encrypt(@PlainText[0], @CipherText[0], Length(PlainText));
      if not Success then
        Exit;

      // Finalize and get the authentication tag
      Success := AES.Final(Tag);
      if not Success then
        Exit;

      // Convert CipherText to string and display it
      Edit1.Text := TNetEncoding.Base64.EncodeBytesToString(CipherText);
      Label1.Caption := 'Encrypted Text Is:';
    finally
      AES.Done;  // Flush AES context to avoid forensic issues
    end;
  except
    // Handle exceptions here if necessary (e.g., log errors)
  end;
end;

procedure TForm1.AESGCMDECRYPT;
begin
  try
    // Retrieve the ciphertext from the Edit1
    CipherText := TNetEncoding.Base64.DecodeStringToBytes(Edit1.Text);

    // Initialize the AES-GCM object with the key
    AES.Init(Key, 256);   // Initialize with the 256-bit key
    try
      // Set nonce for decryption
      AES.Reset(@Nonce, SizeOf(Nonce));

      // Allocate space for the decrypted text
      SetLength(DecryptedText, Length(CipherText) - 16); // Adjust length for tag removal

      // Decrypt the ciphertext
      Success := AES.Decrypt(@CipherText[0], @DecryptedText[0], Length(CipherText) - 16, @Tag, SizeOf(Tag));
      if not Success then
        Exit;

      // Convert DecryptedText to string and display it
      Edit1.Text := TEncoding.UTF8.GetString(DecryptedText);
      Label1.Caption := 'Decrypted Text Is:';
    finally
      AES.Done;  // Flush AES context to avoid forensic issues
    end;
  except
    // Handle exceptions here if necessary (e.g., log errors)
  end;
end;


end.

