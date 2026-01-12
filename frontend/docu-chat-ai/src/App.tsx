import { createBrowserRouter, RouterProvider } from "react-router-dom";
import MainLayout from "./app/shared/pages/MainLayout.tsx";
import ErrorPage from "./app/shared/pages/ErrorPage.tsx";

const router = createBrowserRouter([
  {
    path: "/",
    element: <MainLayout />,
    errorElement: <ErrorPage />,
    children: [],
  },
]);

function App() {
  return <RouterProvider router={router} />;
}

export default App;
