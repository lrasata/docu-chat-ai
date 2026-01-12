import Box from "@mui/material/Box";
import Button from "@mui/material/Button";
import type { AuthContextProps } from "react-oidc-context";
import React from "react";
import Typography from "@mui/material/Typography";
import Card from "@mui/material/Card";
import CardContent from "@mui/material/CardContent";

interface SignInWithGoogleProps {
  googleImgSrc: string;
  googleImgAlt: string;
  buttonText: string;
  auth: AuthContextProps;
}
const SignInWithGoogle: React.FC<SignInWithGoogleProps> = ({
  googleImgAlt,
  googleImgSrc,
  buttonText,
  auth,
}) => (
  <Box
    display="flex"
    flexDirection="column"
    justifyContent="center"
    alignItems="center"
    height="100vh"
  >
    <Card sx={{ minWidth: 300, backgroundColor: "grey.100" }}>
      <CardContent>
        <Typography variant="h2" mb={4}>
          Sign in
        </Typography>
        <Typography variant="h3" mb={2}>
          with other accounts
        </Typography>
        <Button
          onClick={() => auth.signinRedirect()}
          variant="outlined"
          startIcon={
            <img src={googleImgSrc} alt={googleImgAlt} width="20" height="20" />
          }
        >
          {buttonText}
        </Button>
      </CardContent>
    </Card>
  </Box>
);

export default SignInWithGoogle;
