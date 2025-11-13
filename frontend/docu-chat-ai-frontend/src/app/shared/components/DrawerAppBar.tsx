import AppBar from "@mui/material/AppBar";
import Box from "@mui/material/Box";
import Divider from "@mui/material/Divider";
import Drawer from "@mui/material/Drawer";
import IconButton from "@mui/material/IconButton";
import ListItem from "@mui/material/ListItem";
import ListItemButton from "@mui/material/ListItemButton";
import ListItemText from "@mui/material/ListItemText";
import MenuIcon from "@mui/icons-material/Menu";
import Toolbar from "@mui/material/Toolbar";
import Typography from "@mui/material/Typography";
import Button from "@mui/material/Button";
import { useState } from "react";
import { Container } from "@mui/material";
import { Link } from "react-router-dom";

interface Props {
  window?: () => Window;
  appName: string;
  logOutMenuItem: { title: string };
  handleOnClickLogout: () => void;
}

const drawerWidth = 240;

const DrawerAppBar = (props: Props) => {
  const { window, logOutMenuItem, handleOnClickLogout } = props;
  const [mobileOpen, setMobileOpen] = useState(false);

  const handleDrawerToggle = () => {
    setMobileOpen((prevState) => !prevState);
  };

  const drawer = (
    <Box onClick={handleDrawerToggle} sx={{ textAlign: "center" }}>
      <Typography
        variant="h6"
        color="textPrimary"
        sx={{ my: 2, textDecoration: "none" }}
        component={Link}
        to="/"
      >
        {props.appName}
      </Typography>

      <Divider />

      <ListItem key={logOutMenuItem.title} disablePadding>
        <ListItemButton
          sx={{ textAlign: "center" }}
          onClick={() => handleOnClickLogout}
        >
          <ListItemText primary={logOutMenuItem.title} />
        </ListItemButton>
      </ListItem>
    </Box>
  );

  const container =
    window !== undefined ? () => window().document.body : undefined;

  return (
    <Box sx={{ display: "flex" }}>
      <AppBar component="nav">
        <Container maxWidth="xl">
          <Toolbar sx={{ padding: "0 !important" }}>
            <IconButton
              color="inherit"
              aria-label="open drawer"
              edge="start"
              onClick={handleDrawerToggle}
              sx={{ my: 2, display: { sm: "none" } }}
            >
              <MenuIcon />
            </IconButton>
            <Typography
              variant="h6"
              color="white"
              sx={{
                textDecoration: "none",
                flexGrow: 1,
                display: { xs: "none", sm: "block" },
              }}
              component={Link}
              to="/"
            >
              {props.appName}
            </Typography>
            <Box sx={{ display: { xs: "none", sm: "block" } }}>
              <Button
                key={logOutMenuItem.title}
                sx={{ color: "white" }}
                onClick={handleOnClickLogout}
              >
                {logOutMenuItem.title}
              </Button>
            </Box>
          </Toolbar>
        </Container>
      </AppBar>
      <nav>
        <Drawer
          container={container}
          variant="temporary"
          open={mobileOpen}
          onClose={handleDrawerToggle}
          ModalProps={{
            keepMounted: true, // Better open performance on mobile.
          }}
          sx={{
            display: { xs: "block", sm: "none" },
            "& .MuiDrawer-paper": {
              boxSizing: "border-box",
              width: drawerWidth,
            },
          }}
        >
          {drawer}
        </Drawer>
      </nav>
    </Box>
  );
};

export default DrawerAppBar;
