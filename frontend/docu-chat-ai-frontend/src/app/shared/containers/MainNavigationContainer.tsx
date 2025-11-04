import DrawerAppBar from "../components/DrawerAppBar.tsx";
import { APP_NAME } from "../constants/constants.ts";
import { useNavigate } from "react-router-dom";
import { useEffect, useState } from "react";

const authNavItems = [{ title: "Log out", url: "/logout" }];

const nonAuthNavItems = [
  { title: "Sign up", url: "/login" },
  { title: "Log in", url: "/login" },
];

const MainNavigationContainer = () => {
  const [isAuthenticated] = useState(false);
  const navigate = useNavigate();
  const [menuContent, setMenuContent] = useState<
    { title: string; url: string }[]
  >([]);

  const handleOnClickNavigate = (href: string) => {
    navigate(href);
  };

  const handleOnClickLogout = async () => {};

  useEffect(() => {
    const addMenuItems = isAuthenticated ? authNavItems : nonAuthNavItems;

    setMenuContent([...addMenuItems]);
  }, [isAuthenticated]);

  return (
    <DrawerAppBar
      appName={APP_NAME}
      navItems={menuContent}
      handleOnClickNavigate={handleOnClickNavigate}
      handleOnClickLogout={handleOnClickLogout}
    />
  );
};

export default MainNavigationContainer;
