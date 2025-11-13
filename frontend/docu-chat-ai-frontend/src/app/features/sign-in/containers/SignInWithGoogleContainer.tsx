import { useAuth } from "react-oidc-context";
import SignInWithGoogle from "../components/SignInWithGoogle.tsx";

const SignInWithGoogleContainer = () => {
  const auth = useAuth();

  return (
    <SignInWithGoogle
      googleImgSrc="https://developers.google.com/identity/images/g-logo.png"
      googleImgAlt="Google logo"
      buttonText="Sign in with Google"
      auth={auth}
    />
  );
};

export default SignInWithGoogleContainer;
